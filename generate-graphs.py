#! /usr/bin/env python3

import matplotlib
matplotlib.rcParams['pdf.fonttype'] = 42
matplotlib.rcParams['ps.fonttype'] = 42

import sys
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

assert (3 / 2) * 2 == 3, "Use python3, not python2"

allowed_executors = {
    "native": "Native",
    "wasm": "rWasm$_{Wasm}$",
    "mswasm-default": "rWasm$_{STH}$",
    "mswasm-notags": "rWasm$_{ST}$",
    "mswasm-baggybounds": "rWasm$_{S}$",
    "wasm-graal": "Graal$_{Wasm}$",
    "mswasm-graal": "Graal$_{ST}$",
}

data = pd.read_csv(sys.argv[1])
data = data[data['Executor'].isin(allowed_executors)]
data = data.rename(columns={'Executor': 'Executor-ID'})

data = pd.merge(left=data,
                right=pd.DataFrame(list(allowed_executors.items()),
                                   columns=['Executor-ID','Executor']),
                left_on='Executor-ID',
                right_on='Executor-ID',
                validate='many_to_one')
data = data[["Test", "Executor", "Timing (s)"]]


def do_plot(output_filename, baseline, allowed, palette, vsplit_at=[]):
    palette = [sns.color_palette("muted")[x] for x in palette]
    mean_native_timing = (
        data[data["Executor"] == 'Native']
        .groupby('Test')['Timing (s)']
        .mean()
        .to_frame()
        .rename(columns={'Timing (s)': 'Mean Native Timing'})
    )

    mean_baseline_timing = (
        data[data["Executor"] == baseline]
        .groupby('Test')['Timing (s)']
        .mean()
        .to_frame()
        .rename(columns={'Timing (s)': 'Mean Baseline Timing'})
    )

    mean_timing = (
        data.groupby(['Test', 'Executor'])
        .mean()
        .rename(columns={'Timing (s)': 'Mean Timing'})
        .reset_index()
    )

    normalized = pd.merge(left=mean_timing,
                          right=mean_native_timing,
                          left_on='Test',
                          right_on='Test',
                          validate='many_to_one')
    normalized = pd.merge(left=normalized,
                          right=mean_baseline_timing,
                          left_on='Test',
                          right_on='Test',
                          validate='many_to_one')

    if baseline == 'Native':
        normalized['Normalized Slowdown'] = (
            normalized['Mean Timing'] / normalized['Mean Native Timing'])
    else:
        normalized['Normalized Slowdown'] = (
            normalized['Mean Timing'] / normalized['Mean Baseline Timing'])
    normalized = normalized[['Test', 'Executor', 'Normalized Slowdown']]

    assert set(normalized['Executor']) == set(allowed_executors.values())
    for x in allowed:
        assert x in allowed_executors.values()

    normalized = normalized[normalized['Executor'].isin(allowed)]

    sns.set_theme(style='whitegrid')
    sns.set_context("paper", font_scale=1.75)
    fig, ax=plt.subplots(figsize=(2 + len(allowed), 6))

    x_axis = ''
    y_axis = f'Normalized Slowdown against {baseline} (Log Scale)'

    graph_data=normalized.rename(columns={
        'Executor': x_axis,
        'Normalized Slowdown': y_axis,
    })

    g = sns.boxplot(x=x_axis,
                    y=y_axis,
                    data=graph_data,
                    order=allowed,
                    whis=10000,
                    palette=palette,
                    ax=ax)
    fig.get_axes()[0].set_yscale('log')
    fig.get_axes()[0].grid(which='minor', axis='y', color=[0.95] * 3)
    g = sns.stripplot(x=x_axis,
                      y=y_axis,
                      data=graph_data,
                      order=allowed,
                      palette=palette,
                      ax=ax)
    for x in vsplit_at:
        g.axvline(x, color=[0, 0, 0, 0.25])

    plt.tight_layout()
    plt.savefig((sys.path[0] or '.') + '/' + output_filename)


do_plot('exec-time-native-baseline.pdf', 'Native',
        [
            "rWasm$_{Wasm}$",
            "rWasm$_{S}$",
            "rWasm$_{ST}$",
            "rWasm$_{STH}$",
            "Graal$_{Wasm}$",
            "Graal$_{ST}$",
        ], [0, 3, 1, 2, 0, 1])

do_plot('exec-time-native-baseline-withvline.pdf', 'Native',
        [
            "rWasm$_{Wasm}$",
            "rWasm$_{S}$",
            "rWasm$_{ST}$",
            "rWasm$_{STH}$",
            "Graal$_{Wasm}$",
            "Graal$_{ST}$",
        ], [0, 3, 1, 2, 0, 1], [3.5])

do_plot('exec-time-native-baseline-wasmonly.pdf', 'Native',
        [
            "rWasm$_{Wasm}$",
            "Graal$_{Wasm}$",
        ], [0, 1])

do_plot('exec-time-rwasm-baseline.pdf', 'rWasm$_{Wasm}$',
        [
            "rWasm$_{S}$",
            "rWasm$_{ST}$",
            "rWasm$_{STH}$",
        ], [2, 3, 4])

do_plot('exec-time-graalwasm-baseline.pdf', 'Graal$_{Wasm}$',
        [
            "Graal$_{ST}$",
        ], [3])
