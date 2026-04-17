# bash-ask

Minimal CLI wrapper that sends a prompt to a chat-completions style API using Bash.

## Requirements

- `bash`
- `curl`
- `jq`

## Setup

Set required environment variables:

```bash
export ASK_API_URL="https://api.groq.com/openai/v1/chat/completions"
export ASK_MODEL="llama-3.3-70b-versatile"
export ASK_API_KEY="your_api_key"
```

Make script executable (once):

```bash
chmod +x ask
```

## Usage Examples

1. Prompt from command-line arguments:

```bash
./ask "Explain what grep does"
```

2. Prompt from stdin:

```bash
echo "Summarize this sentence." | ./ask
```

3. Combined arguments + stdin (script concatenates both):

```bash
echo "and give 3 bullet points" | ./ask "Summarize Linux pipes"
```

## Example Use Case 

Command:

```bash
./ask "Write a short welcome message for a new engineering intern."
```

Example response:

```text
Welcome to the team! We are excited to have you here and look forward to building great things together.
```

## Known Limitations

- Expects a response compatible with `.choices[0].message.content`.
- No retry, timeout, or backoff logic for network/API failures.
- Prints the full prompt before sending, which may expose sensitive input in terminal history.
- No conversation state; each call is a single independent request.
