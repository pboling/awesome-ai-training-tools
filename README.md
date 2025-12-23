# 😎 Awesome AI Training Tools

| ✨️                                                                                                              |
| ---------------------------------------------------------------------------------------------------------------- |
| A curated list of awesome tools used by human experts to design structured tasks for AI training and evaluation. |

## Contents

- [Task Design & Orchestration](#task-design--orchestration)
- [Benchmarking & Evaluation](#benchmarking--evaluation)
- [Data Annotation & Labeling](#data-annotation--labeling)
- [Synthetic Data Generation](#synthetic-data-generation)
- [Workflow Automation](#workflow-automation)
- [Quality Assurance](#quality-assurance)

## Task Design & Orchestration

Tools for creating, managing, and orchestrating structured AI training tasks.

- **[Harbor](https://github.com/laude-institute/harbor)** - Next-generation platform for designing and managing structured AI training tasks with human-in-the-loop workflows.
  - Example setup script for atomic Fedora systems: [scripts/harbor/setup-harbor-distrobox.sh](scripts/harbor/setup-harbor-distrobox.sh)
- **[Label Studio](https://github.com/heartexlabs/label-studio)** - Open-source data labeling platform with support for multiple data types and ML-assisted labeling.
- **[Prodigy](https://prodi.gy/)** - Scriptable annotation tool for creating training data with active learning capabilities.
- **[Argilla](https://github.com/argilla-io/argilla)** - Collaboration platform for AI engineers and domain experts to build high-quality datasets.

## Benchmarking & Evaluation

Tools for evaluating AI model performance and creating benchmark datasets.

- **[Terminal-Bench](https://github.com/laude-institute/terminal-bench)** - Previous-generation benchmarking framework for evaluating AI agents on structured terminal tasks. Mostly integrated into and superceded by [Harbor](https://github.com/laude-institute/harbor).
- **[EleutherAI LM Evaluation Harness](https://github.com/EleutherAI/lm-evaluation-harness)** - Framework for evaluating language models across a diverse set of tasks.
- **[HELM](https://github.com/stanford-crfm/helm)** - Holistic Evaluation of Language Models by Stanford CRFM.
- **[BIG-bench](https://github.com/google/BIG-bench)** - Beyond the Imitation Game benchmark for large language models.

## Data Annotation & Labeling

Specialized tools for annotating and labeling training data.

- **[CVAT](https://github.com/opencv/cvat)** - Computer Vision Annotation Tool for image and video annotation.
- **[Labelbox](https://labelbox.com/)** - Enterprise platform for creating and managing training data.
- **[Doccano](https://github.com/doccano/doccano)** - Open-source text annotation tool for machine learning practitioners.
- **[Superintendent](https://github.com/janfreyberg/superintendent)** - Interactive labeling tool for Python with active learning support.

## Synthetic Data Generation

Tools for generating synthetic training data.

- (legacy) **[Snorkel](https://github.com/snorkel-team/snorkel)** - System for programmatically building and managing training datasets using weak supervision.
- **[Faker](https://github.com/joke2k/faker)** - Python library for generating fake data for testing and training.
- **[SDV](https://github.com/sdv-dev/SDV)** - Synthetic Data Vault for generating synthetic tabular, relational, and time series data.
- **[Gretel](https://gretel.ai/)** - Platform for generating synthetic data that preserves statistical properties.

## Workflow Automation

Tools for automating AI training workflows and pipelines.

- **[Prefect](https://github.com/PrefectHQ/prefect)** - Workflow orchestration framework for building data pipelines.
- **[Airflow](https://github.com/apache/airflow)** - Platform to programmatically author, schedule, and monitor workflows.
- **[Metaflow](https://github.com/Netflix/metaflow)** - Human-friendly Python library for building and managing ML workflows.
- **[DVC](https://github.com/iterative/dvc)** - Data Version Control for ML projects.

## Quality Assurance

Tools for ensuring quality and consistency in AI training data.

- **[Great Expectations](https://github.com/great-expectations/great_expectations)** - Framework for validating, documenting, and profiling data.
- **[Cleanlab](https://github.com/cleanlab/cleanlab)** - Standard data-centric AI package for finding and fixing label errors.
- **[Rubrix](https://github.com/recognai/rubrix)** - Production-ready framework for exploring, annotating, and managing data for NLP projects.
- **[Evidently AI](https://github.com/evidentlyai/evidently)** - Open-source tool for ML model monitoring and data drift detection.

## Contributing

Contributions are welcome! Please read the [contribution guidelines](./CONTRIBUTING.md) first.

## License

The awesome list is licensed under CC0.

[![CC0](https://licensebuttons.net/p/zero/1.0/88x31.png)](https://creativecommons.org/publicdomain/zero/1.0/)

The scripts in [scripts/](scripts) are licensed under MIT.

[![MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
