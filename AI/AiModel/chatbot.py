import torch
import torch.nn as nn
from torch.nn import functional as F

# parser = argparse.ArgumentParser(description="This is a demonstration program")


# parser.add_argument(
#     "-batch_size", type=str, required=True, help="Please provide a batch_size"
# )
# args = parser.parse_args()

device = "cuda" if torch.cuda.is_available() else "cpu"

batch_size = 16
block_size = 32
max_iters = 50000
learning_rate = 5e-5
eval_iters = 100
n_embd = 192
n_head = 4
n_layer = 6
dropout = 0.1

print(device)


chars = ""
with open("spotify_millsongdata.txt", "r", encoding="utf-8") as f:
    text = f.read()
    chars = sorted(set(text))
# with open("openwebtext/vocab.txt", "r", encoding="utf-8") as f:
#     text = f.read()
#     chars = sorted(list(set(text)))
print(len(text))
vocab_size = len(chars)
print(vocab_size)
string_to_int = {ch: i for i, ch in enumerate(chars)}
int_to_string = {i: ch for i, ch in enumerate(chars)}

encode = lambda s: [string_to_int[c] for c in s]
decode = lambda l: "".join([int_to_string[i] for i in l])

data = torch.tensor(encode(text), dtype=torch.long)
print(data[:100])


class Head(nn.Module):
    """one head of self-attention"""

    def __init__(self, head_size):
        super().__init__()
        self.key = nn.Linear(n_embd, head_size, bias=False)
        self.query = nn.Linear(n_embd, head_size, bias=False)
        self.value = nn.Linear(n_embd, head_size, bias=False)
        self.register_buffer("tril", torch.tril(torch.ones(block_size, block_size)))

        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        B, T, C = x.shape
        k = self.key(x)
        q = self.query(x)

        wei = q @ k.transpose(-2, -1) * k.shape[-1] ** -0.5
        wei = wei.masked_fill(self.tril[:T, :T] == 0, float("-inf"))
        wei = F.softmax(wei, dim=-1)
        wei = self.dropout(wei)

        v = self.value(x)
        out = wei @ v
        return out


class MultiHeadAttention(nn.Module):
    """multiple heads of self-attention in parallel"""

    def __init__(self, num_heads, head_size):
        super().__init__()
        self.heads = nn.ModuleList([Head(head_size) for _ in range(num_heads)])
        self.proj = nn.Linear(head_size * num_heads, n_embd)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x):
        out = torch.cat([h(x) for h in self.heads], dim=-1)
        out = self.dropout(self.proj(out))
        return out


class FeedFoward(nn.Module):
    """a simple linear layer followed by a non-linearity"""

    def __init__(self, n_embd):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(n_embd, 4 * n_embd),
            nn.ReLU(),
            nn.Linear(4 * n_embd, n_embd),
            nn.Dropout(dropout),
        )

    def forward(self, x):
        return self.net(x)


class Block(nn.Module):
    """Transformer block: communication followed by computation"""

    def __init__(self, n_embd, n_head):
        super().__init__()
        head_size = n_embd // n_head
        self.sa = MultiHeadAttention(n_head, head_size)
        self.ffwd = FeedFoward(n_embd)
        self.ln1 = nn.LayerNorm(n_embd)
        self.ln2 = nn.LayerNorm(n_embd)

    def forward(self, x):
        y = self.sa(x)
        x = self.ln1(x + y)
        y = self.ffwd(x)
        x = self.ln2(x + y)
        return x


class GPTLanguageModel(nn.Module):
    def __init__(self, vocab_size):
        super().__init__()
        self.token_embedding_table = nn.Embedding(vocab_size, n_embd)
        self.position_embedding_table = nn.Embedding(block_size, n_embd)
        self.blocks = nn.Sequential(
            *[Block(n_embd, n_head=n_head) for _ in range(n_layer)]
        )
        self.ln_f = nn.LayerNorm(n_embd)
        self.lm_head = nn.Linear(n_embd, vocab_size)

        self.apply(self._init_weights)

    def _init_weights(self, module):
        if isinstance(module, nn.Linear):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)
            if module.bias is not None:
                torch.nn.init.zeros_(module.bias)
        elif isinstance(module, nn.Embedding):
            torch.nn.init.normal_(module.weight, mean=0.0, std=0.02)

    def forward(self, index, targets=None):
        B, T = index.shape

        tok_emb = self.token_embedding_table(index)
        pos_emb = self.position_embedding_table(torch.arange(T, device=device))
        x = tok_emb + pos_emb
        x = self.blocks(x)
        x = self.ln_f(x)
        logits = self.lm_head(x)

        if targets is None:
            loss = None
        else:
            B, T, C = logits.shape
            logits = logits.view(B * T, C)
            targets = targets.view(B * T)
            loss = F.cross_entropy(logits, targets)

        return logits, loss

    def generate(self, index, max_new_tokens):
        for _ in range(max_new_tokens):
            index_cond = index[:, -block_size:]

            logits, loss = self.forward(index_cond)

            logits = logits[:, -1, :]

            probs = F.softmax(logits, dim=-1)

            index_next = torch.multinomial(probs, num_samples=1)

            index = torch.cat((index, index_next), dim=1)  # (B, T+1)
        return index


# model = GPTLanguageModel(vocab_size)
# print("loading model parameters...")
# with open("model-01.pkl", "rb") as f:
#     model = pickle.load(f)
# print("loaded successfully!")
model = GPTLanguageModel(vocab_size)
model.load_state_dict(torch.load("model-01.pth", map_location=device))
model.eval()  # Ensure the model is in evaluation mode
print("Model loaded successfully.")

m = model.to(device)


def textcall(prompt):
    context = torch.tensor(encode(prompt), dtype=torch.long, device=device)
    generated_chars = decode(
        m.generate(context.unsqueeze(0), max_new_tokens=100)[0].tolist()
    )
    print(f"Completion:\n{generated_chars}")
    return generated_chars
