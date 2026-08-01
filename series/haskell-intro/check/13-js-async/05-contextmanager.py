"""Python の with は、実はジェネレーターで実装できる。

つまり「コルーチン」と「リソース管理」は別の応用ではなく同じ仕組み。
構成案 6（コルーチン）と 7（リソース管理）を繋ぐ材料になる。
"""

from contextlib import contextmanager


@contextmanager
def res(name):
    print(f"open  {name}")
    try:
        yield name  # ここで中断し、with の本体が走る
    finally:
        print(f"close {name}")


print("=== @contextmanager: yield の位置で with の本体が走る ===")
with res("A") as a, res("B") as b:
    print(f"use {a}{b}")

# 上と同じことを、ジェネレーターを手で駆動して書く。
# body が継続そのもの。with_ は Haskell の runContT に相当する。
def with_(gen, body):
    value = next(gen)  # setup してから中断
    try:
        body(value)  # ← ここが継続
    finally:
        try:
            next(gen)  # teardown（yield の後ろ）を走らせる
        except StopIteration:
            pass


print("=== ジェネレーターを手で駆動する（body が継続） ===")
with_(res("A").gen, lambda a: with_(res("B").gen, lambda b: print(f"use {a}{b}")))

# 例外時も teardown が走ることの確認
print("=== 例外が起きても close される ===")
try:
    with res("A"):
        raise RuntimeError("boom")
except RuntimeError as e:
    print(f"caught: {e}")
