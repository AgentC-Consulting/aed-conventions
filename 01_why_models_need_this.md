# 01 · Why Models Need This

*Excerpted **verbatim** from the author's `naming_conventions.md`, lifted to the
front of the reading order because it explains why every later rule exists.
The complete original — with this passage in place — is
[02_naming_conventions.md](02_naming_conventions.md).*

---

Naming conventions are one of the ways that drive the agent enhanced development workflow. The reason for this is that AI models use token windows to understand the context of things.&#x20;

## Basic Explanation of Tokens & Token Window

AI models, specifically LLMs, use tokens to represent groups of text. For example the statement:

`I want to create a new user and assign them to an account.`

For this example I’ll use Llama 3 to tokenize this prompt. When we tokenize this prompt, it turns into these tokens:

\`

```
'I'
' want'
' to'
' create'
' a'
' new'
' user'
' and'
' assign'
' them'
' to'
' an'
' account'
'.'
```

The extra spaces inside of the single quotes here is to highlight that spaces can be part of a token. Now when the AI model is scanning through the prompt, it’s going to read a group of tokens at a time, shifting down as it processes. For this example I’ll use a 8 token window, shifting 4 tokens at a time so there is some overlap.

Starting token window `’I want to create a new user and’`

Next token window `’ a new user and assign them to an’`

Final token window `‘ assign them to an account.’`

This window is typically larger than this, but for this example it illustrates how as the window shifts and the LLM model associates groups of tokens. This association is how the relationship of a flow of words is established and influences the direction that the model computes. This is why a naming convention needs to be very consistent.

---

*Chapter 01 of the AED canon · continue to
[02 · Naming Conventions](02_naming_conventions.md) ·
[reading order](README.md#reading-order)*
