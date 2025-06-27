# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "dspy==2.6.27",
#     "funnydspy==0.4.0",
#     "marimo",
#     "math-equivalence @ git+https://github.com/hendrycks/math.git",
#     "nbformat==5.10.4",
# ]
# ///

import marimo

__generated_with = "0.13.15"
app = marimo.App(width="medium", auto_download=["ipynb"])

with app.setup:
    # Initialization code that runs before all other cells
    import subprocess

    subprocess.run(["uv", "pip", "install", "git+https://github.com/hendrycks/math.git"])


@app.cell
def _():
    import marimo as mo
    return


@app.cell
def _():
    import funnydspy as fd
    import dspy
    from dataclasses import dataclass
    from typing import List, NamedTuple

    return List, NamedTuple, dspy, fd


@app.cell
def _(dspy, fd):
    # Configure your language model, using environment variables OPENAI_API_BASE and OPENAI_API_KEY
    import os

    dspy.configure(lm=dspy.LM(f"openai/{os.environ['OPENAI_API_MODEL']}"))

    @fd.ChainOfThought
    def rag(query: str, context: str) -> str:
        return answer

    # Get Python objects directly
    answer = rag("What is the capital of France?", "France is a country in Europe.")
    # → "The capital of France is Paris."

    # Get DSPy Prediction for optimization
    pred1 = rag(
        "What is the capital of France?",
        "France is a country in Europe.",
        _prediction=True,
    )
    # → dspy.Prediction(reasoning="...", answer="The capital of France is Paris.")
    return answer, pred1


@app.cell
def _(answer):
    answer
    return


@app.cell
def _(pred1):
    pred1
    return


@app.cell
def _(NamedTuple, fd):
    @fd.ChainOfThought
    def analyze(numbers: list[float], threshold: float) -> tuple[float, list[float]]:
        """Analyze numbers and return statistics."""

        class Stats(NamedTuple):
            mean: float  # The average of the numbers
            above: list[float]  # Numbers above the threshold

        return Stats

    # Get Python objects directly
    mean_val, above_vals = analyze([1, 5, 3, 8, 2], 4.0)
    # → (4.0, [5.0, 8.0])

    # Get DSPy Prediction for optimization
    pred2 = analyze([1, 5, 3, 8, 2], 4.0, _prediction=True)
    # → dspy.Prediction(reasoning="...", mean=4.0, above=[5.0, 8.0])
    return (pred2,)


@app.cell
def _(pred2):
    pred2
    return


@app.cell
def _(List, fd):
    @fd.ChainOfThought
    def summarize_text(text: str) -> tuple[str, int, List[str]]:
        """Summarize text and extract key information."""
        summary = "A concise summary of the text"
        word_count = "Total number of words"
        key_points = "List of main points"
        return summary, word_count, key_points

    summary, count, points = (
        summarize_text("""Modules help you describe AI behavior as code, not strings.
    To build reliable AI systems, you must iterate fast. But maintaining prompts makes that hard: it forces you to tinker with strings or data every time you change your LM, metrics, or pipeline. Having built over a dozen best-in-class compound LM systems since 2020, we learned this the hard way—and so built DSPy to decouple AI system design from messy incidental choices about specific LMs or prompting strategies.""")
    )
    return (summary,)


@app.cell
def _(summary):
    print(summary)
    return


@app.cell
def _():
    from dspy.datasets import MATH

    dataset = MATH(subset="algebra")
    return (dataset,)


@app.cell
def _(fd):
    @fd.Predict
    def analyze_data(question: str) -> str:
        """Work on the math problem and give an answer"""
        answer = "the answer to the math problem"
        return answer

    return (analyze_data,)


@app.cell
def _(dataset):
    dataset.train[0]
    return


@app.cell
def _(dataset):
    dataset.train[10:13]
    return


@app.cell
def _(analyze_data, dataset, dspy):
    # Access the underlying DSPy module for optimization
    optimizer = dspy.SIMBA(
        metric=dataset.metric, bsize=4, num_candidates=4, max_steps=1, max_demos=4
    )
    compiled_analyze = optimizer.compile(
        analyze_data.module, trainset=dataset.train[10:14]
    )
    return (compiled_analyze,)


@app.cell
def _(compiled_analyze, fd):
    # Wrap the optimized module back into a Pythonic interface
    analyze_optimized = fd.funnier(compiled_analyze)
    return (analyze_optimized,)


@app.cell
def _(compiled_analyze):
    compiled_analyze
    return


@app.cell
def _(analyze_data, analyze_optimized, dataset):
    for q in dataset.train[7:9]:
        print(
            f"{q['answer']}: {analyze_data(q['question'])}, {analyze_optimized(q['question'])}\n"
        )
    return


@app.cell
def _(compiled_analyze):
    compiled_analyze.save("output/analyze_optimized.json")
    return


@app.cell
def _():
    # inspect the content of output/analyze_optimized.json
    import json

    with open("output/analyze_optimized.json", "r") as file:
        data = json.load(file)
        print(data)
    return


@app.cell
def _(compiled_analyze, dataset, dspy):
    devset = dataset.dev[10:14]
    evaluate = dspy.Evaluate(devset=devset, metric=dataset.metric, num_threads=4, display_progress=True, display_table=0, max_errors=999)
    evaluate(compiled_analyze)
    return


if __name__ == "__main__":
    app.run()
