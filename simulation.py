import os
import sys
import argparse
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn import datasets
from sklearn.model_selection import train_test_split


def stable_softmax(logits):
    shifted = logits - np.max(logits, axis=1, keepdims=True)
    exp_vals = np.exp(shifted)
    return exp_vals / np.sum(exp_vals, axis=1, keepdims=True)


def main():
    parser = argparse.ArgumentParser(description="Phase 3 Iris Classification Model")
    parser.add_argument("--output-dir", default="build/phase3",
                        help="Output directory for artifacts (default: build/phase3)")
    parser.add_argument("--vector-file", default="hdl_export/test_bench/data/iris_vectors.txt",
                        help="Output path for hardware test vectors")
    args = parser.parse_args()

    output_dir = args.output_dir
    vector_file = args.vector_file
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(os.path.dirname(vector_file), exist_ok=True)

    np.random.seed(42)

    iris = datasets.load_iris()
    X_raw = (iris.data * 10).astype(np.int64)
    y = iris.target

    X_train, X_test, y_train, y_test = train_test_split(
        X_raw, y, test_size=0.2, stratify=y, random_state=42
    )

    X_train_f = X_train.astype(np.float64)
    X_test_f = X_test.astype(np.float64)

    num_classes = 3
    y_train_onehot = np.eye(num_classes, dtype=np.float64)[y_train]
    y_test_onehot = np.eye(num_classes, dtype=np.float64)[y_test]

    W = np.zeros((4, 3), dtype=np.float64)
    b = np.zeros((1, 3), dtype=np.float64)

    epochs = 5000
    learning_rate = 0.001
    n_samples = X_train_f.shape[0]

    train_losses = []
    test_accs = []

    for epoch in range(epochs):
        logits = X_train_f @ W + b
        probs = stable_softmax(logits)

        eps = 1e-12
        loss = -np.mean(np.sum(y_train_onehot * np.log(probs + eps), axis=1))
        train_losses.append(loss)

        test_logits = X_test_f @ W + b
        test_pred = np.argmax(test_logits, axis=1)
        test_acc = np.mean(test_pred == y_test)
        test_accs.append(test_acc)

        d_logits = (probs - y_train_onehot) / n_samples
        dW = X_train_f.T @ d_logits
        db = np.sum(d_logits, axis=0, keepdims=True)

        W = W - learning_rate * dW
        b = b - learning_rate * db

    quant_scale = 256
    W_q = np.rint(W * quant_scale).astype(np.int64)
    b_q = np.rint(b.flatten() * quant_scale).astype(np.int64)

    expected_W = np.array([
        [39, 33, -72],
        [83, 5, -88],
        [-112, -12, 124],
        [-54, -49, 103]
    ], dtype=np.int64)

    expected_b = np.array([2, 7, -9], dtype=np.int64)

    if not np.array_equal(W_q, expected_W):
        print(f"Expected weights:\n{expected_W}")
        print(f"Got weights:\n{W_q}")
        raise RuntimeError("Quantized weights do not match expected values")

    if not np.array_equal(b_q, expected_b):
        print(f"Expected biases: {expected_b}")
        print(f"Got biases: {b_q}")
        raise RuntimeError("Quantized biases do not match expected values")

    float_test_logits = X_test_f @ W + b
    float_test_pred = np.argmax(float_test_logits, axis=1)
    float_test_acc = float(np.mean(float_test_pred == y_test))

    W_class_by_feature = W_q.T.copy()

    def quantized_predict(X_data):
        preds = []
        margins = []
        uncertains = []
        scores_list = []
        for i in range(X_data.shape[0]):
            scores = np.zeros(3, dtype=np.int64)
            for c in range(3):
                s = int(b_q[c])
                for f in range(4):
                    s += int(X_data[i, f]) * int(W_class_by_feature[c, f])
                scores[c] = s
            scores_list.append(scores.copy())
            best_idx = 0
            best_val = scores[0]
            for c in range(1, 3):
                if scores[c] > best_val:
                    best_val = scores[c]
                    best_idx = c
            sorted_scores = sorted(scores.tolist(), reverse=True)
            margin = sorted_scores[0] - sorted_scores[1]
            uncertain = 1 if margin < 128 else 0
            preds.append(best_idx)
            margins.append(margin)
            uncertains.append(uncertain)
        return np.array(preds), np.array(margins), np.array(uncertains), scores_list

    q_test_pred, q_test_margins, q_test_uncertains, _ = quantized_predict(X_test)
    quantized_test_acc = float(np.mean(q_test_pred == y_test))

    q_full_pred, q_full_margins, q_full_uncertains, _ = quantized_predict(X_raw)
    quantized_full_acc = float(np.mean(q_full_pred == y))
    full_error_count = int(np.sum(q_full_pred != y))
    uncertain_count = int(np.sum(q_full_uncertains == 1))

    misclassified = (q_full_pred != y)
    uncertain_and_wrong = int(np.sum((q_full_uncertains == 1) & misclassified))
    uncertain_and_correct = int(np.sum((q_full_uncertains == 1) & (~misclassified)))

    assert quantized_test_acc == 1.0, f"Quantized test accuracy is {quantized_test_acc}, expected 1.0"
    assert quantized_full_acc >= 0.96, f"Quantized full accuracy is {quantized_full_acc}, expected >= 0.96"

    cm = np.zeros((3, 3), dtype=np.int64)
    for i in range(len(y)):
        cm[y[i], q_full_pred[i]] += 1

    with open(vector_file, 'w') as f:
        for i in range(X_raw.shape[0]):
            f0 = int(X_raw[i, 0])
            f1 = int(X_raw[i, 1])
            f2 = int(X_raw[i, 2])
            f3 = int(X_raw[i, 3])
            bits = f"{f0:08b}{f1:08b}{f2:08b}{f3:08b}"
            assert len(bits) == 32
            f.write(f"{bits} {q_full_pred[i]} {q_full_uncertains[i]} {q_full_margins[i]}\n")

    metrics = {
        "epochs": epochs,
        "learning_rate": learning_rate,
        "quantization_scale": quant_scale,
        "uncertainty_threshold": 128,
        "float_test_accuracy": float_test_acc,
        "quantized_test_accuracy": quantized_test_acc,
        "quantized_full_dataset_accuracy": quantized_full_acc,
        "full_dataset_sample_count": len(y),
        "full_dataset_error_count": full_error_count,
        "uncertain_sample_count": uncertain_count,
        "uncertain_error_count": uncertain_and_wrong,
        "uncertain_correct_count": uncertain_and_correct,
        "hardware_vector_count": len(X_raw)
    }

    with open(os.path.join(output_dir, "metrics.json"), 'w') as f:
        json.dump(metrics, f, indent=2)

    feature_order = [
        "Sepal Length (Feature 0)",
        "Sepal Width (Feature 1)",
        "Petal Length (Feature 2)",
        "Petal Width (Feature 3)"
    ]
    class_order = ["Setosa (Class 0)", "Versicolor (Class 1)", "Virginica (Class 2)"]

    model_params = {
        "feature_order": feature_order,
        "class_order": class_order,
        "weights_feature_by_class": W_q.tolist(),
        "weights_class_by_feature": W_class_by_feature.tolist(),
        "biases": b_q.tolist(),
        "input_width": 8,
        "weight_width": 8,
        "score_width": 24,
        "quantization_scale": quant_scale,
        "uncertainty_threshold": 128
    }

    with open(os.path.join(output_dir, "model_parameters.json"), 'w') as f:
        json.dump(model_params, f, indent=2)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))
    ax1.plot(train_losses, label='Train Loss', color='#e74c3c', linewidth=2)
    ax1.set_xlabel('Epochs', fontweight='bold')
    ax1.set_ylabel('Loss (Categorical Cross-Entropy)', fontweight='bold')
    ax1.set_title('Training Loss', fontsize=11, fontweight='bold')
    ax1.legend()
    ax2.plot(test_accs, label='Test Acc', color='#2ecc71', linewidth=2)
    ax2.set_xlabel('Epochs', fontweight='bold')
    ax2.set_ylabel('Accuracy', fontweight='bold')
    ax2.set_title('Test Accuracy', fontsize=11, fontweight='bold')
    ax2.legend()
    plt.suptitle('Phase 3 Training History', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'training_history.png'), dpi=150)
    plt.close()

    fig, ax = plt.subplots(figsize=(6, 5))
    class_names = ['Setosa', 'Versicolor', 'Virginica']
    im = ax.imshow(cm, cmap='Blues', aspect='auto')
    ax.set_xticks(range(3))
    ax.set_yticks(range(3))
    ax.set_xticklabels(class_names)
    ax.set_yticklabels(class_names)
    for i in range(3):
        for j in range(3):
            ax.text(j, i, str(cm[i, j]), ha='center', va='center',
                    fontsize=14, fontweight='bold',
                    color='white' if cm[i, j] > cm.max() / 2 else 'black')
    ax.set_ylabel('Actual Label', fontweight='bold')
    ax.set_xlabel('Predicted Label', fontweight='bold')
    ax.set_title('Quantized Model Confusion Matrix', fontsize=12, fontweight='bold')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'quantized_confusion_matrix.png'), dpi=150)
    plt.close()

    correct_mask = (q_full_pred == y)
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.hist(q_full_margins[correct_mask], bins=30, alpha=0.7, label='Correct', color='#2ecc71', edgecolor='black')
    ax.hist(q_full_margins[~correct_mask], bins=30, alpha=0.7, label='Misclassified', color='#e74c3c', edgecolor='black')
    ax.axvline(x=128, color='black', linestyle='--', linewidth=2, label='Threshold (128)')
    ax.set_xlabel('Confidence Margin', fontweight='bold')
    ax.set_ylabel('Count', fontweight='bold')
    ax.set_title('Confidence Margin Distribution', fontsize=12, fontweight='bold')
    ax.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'confidence_margin_distribution.png'), dpi=150)
    plt.close()

    assert os.path.isfile(vector_file)
    with open(vector_file, 'r') as f:
        lines = f.readlines()
    assert len(lines) == 150, f"Expected 150 vectors, got {len(lines)}"
    assert len(X_raw) == 150

    print(f"Float test accuracy: {float_test_acc}")
    print(f"Quantized test accuracy: {quantized_test_acc}")
    print(f"Quantized full dataset accuracy: {quantized_full_acc}")
    print(f"Number of hardware vectors: {len(X_raw)}")
    print(f"Number of uncertain samples: {uncertain_count}")
    print(f"Number of misclassified samples: {full_error_count}")
    print(f"Number of misclassified samples captured by uncertainty flag: {uncertain_and_wrong}")
    print(f"Quantized weights:\n{W_q}")
    print(f"Quantized biases: {b_q}")
    print(f"Vector file path: {vector_file}")
    print(f"Artifact directory: {output_dir}")


if __name__ == "__main__":
    main()
