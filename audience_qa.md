# Audience questions

Selected questions from the live session chat, with answers.

## How much data is typically needed for training at each stage?

It depends, but a few hundred high-quality examples is a good starting point for SFT, and most tasks end up somewhere around 1k–10k. For comparison, [LIMA](https://arxiv.org/abs/2305.11206) got a capable general assistant from just 1,000 carefully chosen examples. There's a lot of variability in how many are needed: it depends on how far the task is from what the model can already do, the quality and diversity of the examples, and the base model (larger models tend to need fewer examples). The usual flow is: train on a few hundred, evaluate, and add more if needed.

OpenAI has a high-level practical write-up: [Supervised fine-tuning guide](https://developers.openai.com/api/docs/guides/supervised-fine-tuning/index.html).

For the general stages shown in the session (where "how much" is usually counted in tokens): pretraining takes trillions of tokens; mid-training, under 10% of the pretraining volume; SFT, as above; preference tuning, typically tens of thousands to a few hundred thousand preference pairs for general alignment, and fewer for narrow tasks. For a fully open example that reports the data used at each post-training stage, see [Tulu 3](https://arxiv.org/abs/2411.15124).

## With a harness, does it wait for the response to finish, so you still need to make sure the model doesn't ramble?

Yes, the harness waits until the model emits a stop token or hits the max-length cap. An instruct model already knows when to stop (unlike a pretrained base model), but RL tends to push response length up, since longer reasoning often earns more reward. So in practice you set a generation cap and decide how truncated rollouts are handled: zero reward, masking them out of the loss, or a soft penalty as they get close to the limit. Sometimes a length penalty is added to the reward too. Long rollouts are also a throughput issue (the whole batch waits for the slowest ones), which is why asynchronous rollouts are common.

## You said fine-tuning doesn't teach knowledge. But the model was trained on many sources, some of them wrong. Can't fine-tuning make it favor your data?

Partly, yes. If the model already saw conflicting information in pretraining, fine-tuning can push it to favor one version (you're basically choosing among things it already knows). But it's not good at adding genuinely new facts: they're learned slowly and tend to increase hallucination ([Gekhman et al., 2024](https://arxiv.org/abs/2405.05904)). And even when it does work, there's no guarantee it will reliably give your version back, you can't trace where the answer came from, and any update means retraining. So if you want the model to rely on your sources, it's better to provide them externally (RAG, a database, an API, a tool, etc.) and use fine-tuning for behavior and format.

## How are coding models trained to handle any kind of coding task, and how many datasets does SFT need?

There's no set number of datasets. SFT is more about covering the range of tasks (writing, debugging, refactoring, tests, multi-file edits, different languages), often with synthetic data from stronger models, filtered by actually running the code. Most of the recent gains in general coding ability come from RLVR, where the model is rewarded for code that actually passes tests or works in a real repository.

If you want a feel for what these RL environments look like, Prime Intellect has a public hub of them: [Environments Hub](https://app.primeintellect.ai/dashboard/environments?ex_sort=most_installs). Each environment is basically a set of tasks (e.g. coding problems), the harness the model runs in, and a check for whether it got the answer right, like running the code against tests. That check is the "verifiable reward." Browsing a few of the coding ones gives a good sense of how it works.

Further reading:
- [SWE-RL](https://arxiv.org/abs/2502.18449) (Meta): reinforcement learning on real software history
- [SWE-smith](https://arxiv.org/abs/2504.21798): how training tasks for coding agents are generated at scale
- [Qwen2.5-Coder Technical Report](https://arxiv.org/abs/2409.12186): what a coding model's training data mix looks like

## For RAG and tool calling, do you need to fine-tune a model to handle the tool calls, for example to look through a 300-page manual?

Most instruct models are already trained on tool calling, so for something like a 300-page manual it's more about the retrieval side: chunking and indexing it, giving the model a search tool, writing good tool descriptions, and maybe reranking. With long-context models, you can sometimes just fit the whole manual in the prompt. Fine-tuning makes sense if you're using a smaller model that isn't reliable at tool calls, if you want to distill the behavior into something cheaper or faster, or if retrieval struggles with domain-specific terms (and then it's often the embedding model you'd fine-tune, not the LLM). So I'd start with prompting and retrieval, evaluate, and only fine-tune if that's not enough.

## In general, how do you choose fine-tuning parameters?

Usually you start from known defaults (papers, model cards, framework configs) and do a small sweep, mainly over learning rate and number of epochs, since those matter most. Track your runs with something like W&B. Auto-tuners like Optuna help, but full searches get expensive with LLMs.

Further reading:
- [LoRA Without Regret](https://thinkingmachines.ai/blog/lora/) (Thinking Machines): learning rate is the main knob, and LoRA needs a much higher one than full fine-tuning
- [Unsloth LoRA hyperparameters guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide): practical defaults
- [Practical tips for fine-tuning LLMs using LoRA](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms) (Sebastian Raschka): experiments with rank, alpha and epochs

## To make the most of "our data," should we use an LLM to organize it, remove duplicates and link related information, so it can navigate the data and retrieve what's relevant to our questions?

Exact duplicates are cheaper to catch with simple methods (hashing, embedding similarity). An LLM is more useful for the fuzzy parts: adding metadata and tags, summarizing documents, and linking related information (roughly what approaches like GraphRAG do). I'd start with a basic RAG setup, see where retrieval fails, and add LLM-based organizing where it helps. Often it isn't needed.

## Can you post-train for vendor-specific language features? For FPGA RTL, LLMs often reach for Xilinx-specific features, even with a system prompt telling them not to.

Yes, fine-tuning suits this case: the model needs to reliably produce one dialect, and its training data pulls it toward another. Whether prompting alone can fix it depends on how the system prompt is written and what context the model sees. If the general step sequence from the talk doesn't fix it, SFT is a good starting point.

You'd need an instruct code model (~7–14B), a few thousand requests paired with portable RTL, a checker, and a held-out eval set. Collecting the training set takes most of the work.

## What's the best way to fine-tune a small model, around 1–3B parameters?

Unsloth is a good starting point: it has [ready-made notebooks](https://unsloth.ai/docs/get-started/unsloth-notebooks) for most small open models, and they run on free Colab or Kaggle GPUs. For a 1–3B model, you'd usually use LoRA (or QLoRA, the 4-bit version, if memory is tight) rather than full fine-tuning, since it's cheaper, faster, and [less likely to make the model forget](https://arxiv.org/abs/2405.09673) what it already knows. Start from the instruct version of the model, use a small but high-quality dataset (a few hundred to a few thousand examples), train for 1–3 epochs, and compare the results against the base model on your own test examples.

## When you say consumer hardware, do you mean 8–16 GB GPUs?

Yes. With about 8 GB of VRAM, you can comfortably do QLoRA on models up to 3B parameters, and on models up to 8B with 16 GB. Unsloth lists the memory needed for each model size in its [requirements](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners/unsloth-requirements).

That's for parameter-efficient fine-tuning (LoRA/QLoRA), where you only train small adapters. This is the default case: full fine-tuning, where you update all the weights, is rarely needed, and LoRA/QLoRA match its quality for typical task adaptation.

## Where to try fine-tuning without your own GPU (free or cheap)

- [Kaggle](https://www.kaggle.com/docs/efficient-gpu-usage): free notebooks with a weekly GPU quota, good for small fine-tuning experiments
- [Google Colab](https://research.google.com/colaboratory/faq.html): browser-based notebooks with a free GPU tier (with usage limits) and paid plans for more power
- [RunPod](https://www.runpod.io/pricing): cloud GPUs rented by the hour, a cheap option when you need more than the free tiers
