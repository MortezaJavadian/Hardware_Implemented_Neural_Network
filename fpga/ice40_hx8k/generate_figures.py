from __future__ import annotations

import argparse
import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


def add_labels(axis, bars, *, decimals: int = 0) -> None:
    for bar in bars:
        height = bar.get_height()
        if decimals == 0:
            label = f"{int(height)}"
        else:
            label = f"{height:.{decimals}f}"

        axis.annotate(
            label,
            xy=(bar.get_x() + bar.get_width() / 2, height),
            xytext=(0, 4),
            textcoords="offset points",
            ha="center",
            va="bottom",
        )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Phase 4 comparison figures."
    )
    parser.add_argument(
        "--metrics",
        type=Path,
        required=True,
        help="Path to phase4_metrics.json",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Directory in which figures are written.",
    )
    args = parser.parse_args()

    if not args.metrics.is_file():
        raise FileNotFoundError(
            f"Metrics file does not exist: {args.metrics}"
        )

    with args.metrics.open("r", encoding="utf-8") as file:
        metrics = json.load(file)

    baseline = metrics["phase3_baseline"]
    linear = metrics["phase4_linear_reference"]
    balanced = metrics["phase4_balanced"]

    args.output_dir.mkdir(parents=True, exist_ok=True)

    labels = [
        "Phase 3\nBaseline",
        "Phase 4\nLinear",
        "Phase 4\nBalanced",
    ]

    # --------------------------------------------------------
    # Latency
    # --------------------------------------------------------

    latency = [
        baseline["latency_cycles"],
        linear["latency_cycles"],
        balanced["latency_cycles"],
    ]

    figure, axis = plt.subplots(figsize=(8, 5))
    bars = axis.bar(labels, latency)

    axis.set_title("Pipeline Latency Comparison")
    axis.set_ylabel("Clock cycles")
    axis.set_ylim(0, max(latency) + 0.75)
    axis.grid(axis="y", linestyle="--", alpha=0.5)

    add_labels(axis, bars)

    figure.tight_layout()
    figure.savefig(
        args.output_dir / "latency_comparison.png",
        dpi=200,
    )
    plt.close(figure)

    # --------------------------------------------------------
    # Fmax
    # --------------------------------------------------------

    fmax_labels = [
        "Phase 4\nLinear",
        "Phase 4\nBalanced",
    ]

    fmax_values = [
        linear["fmax_mhz"],
        balanced["fmax_mhz"],
    ]

    target_frequency = metrics["target"]["target_frequency_mhz"]

    figure, axis = plt.subplots(figsize=(8, 5))
    bars = axis.bar(fmax_labels, fmax_values)

    axis.axhline(
        target_frequency,
        linestyle="--",
        label=f"Target: {target_frequency:.0f} MHz",
    )

    axis.set_title("Maximum Frequency Comparison")
    axis.set_ylabel("Frequency (MHz)")
    axis.set_ylim(0, max(fmax_values) * 1.22)
    axis.grid(axis="y", linestyle="--", alpha=0.5)
    axis.legend()

    add_labels(axis, bars, decimals=2)

    axis.text(
        0.02,
        0.96,
        "Phase 3 baseline: Fmax not available\n"
        "(no internal register-to-register timing path)",
        transform=axis.transAxes,
        ha="left",
        va="top",
    )

    figure.tight_layout()
    figure.savefig(
        args.output_dir / "fmax_comparison.png",
        dpi=200,
    )
    plt.close(figure)

    # --------------------------------------------------------
    # Yosys resources
    # --------------------------------------------------------

    lut_values = [
        baseline["yosys_lut"],
        linear["yosys_lut"],
        balanced["yosys_lut"],
    ]

    dff_values = [
        baseline["yosys_dff"],
        linear["yosys_dff"],
        balanced["yosys_dff"],
    ]

    carry_values = [
        baseline["yosys_carry"],
        linear["yosys_carry"],
        balanced["yosys_carry"],
    ]

    x_positions = np.arange(len(labels))
    width = 0.24

    figure, axis = plt.subplots(figsize=(10, 6))

    lut_bars = axis.bar(
        x_positions - width,
        lut_values,
        width,
        label="LUT",
    )

    dff_bars = axis.bar(
        x_positions,
        dff_values,
        width,
        label="DFF",
    )

    carry_bars = axis.bar(
        x_positions + width,
        carry_values,
        width,
        label="Carry",
    )

    axis.set_title("Yosys Resource Utilization")
    axis.set_ylabel("Primitive count")
    axis.set_xticks(x_positions)
    axis.set_xticklabels(labels)
    axis.grid(axis="y", linestyle="--", alpha=0.5)
    axis.legend()

    add_labels(axis, lut_bars)
    add_labels(axis, dff_bars)
    add_labels(axis, carry_bars)

    figure.tight_layout()
    figure.savefig(
        args.output_dir / "resource_utilization.png",
        dpi=200,
    )
    plt.close(figure)

    print("Generated Phase 4 figures:")
    for filename in (
        "latency_comparison.png",
        "fmax_comparison.png",
        "resource_utilization.png",
    ):
        print(args.output_dir / filename)


if __name__ == "__main__":
    main()
