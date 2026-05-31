#!/usr/bin/env python3
"""
verify_math.py — утилита верификации математики курса «Логика и принятие решений».
Принцип системы: ЛЮБУЮ формулу интерактива проверяем здесь (несколько профилей,
границы, монотонность) ДО верстки, затем дублируем ту же формулу в JS модуля.
Запуск:  python3 verify_math.py
"""
import math
from itertools import combinations

ok = 0
def check(name, got, exp, tol=1e-9):
    global ok
    good = abs(got - exp) <= tol if isinstance(exp, (int, float)) else got == exp
    print(f"  {'✓' if good else '✗'} {name}: {got}")
    assert good, f"FAIL {name}: {got} != {exp}"
    ok += 1

print("== Гл.2 · Ожидаемая стоимость E[X] = Σ pᵢ·vᵢ ==")
def ev(pairs):                      # pairs = [(p, v), ...]
    assert abs(sum(p for p, _ in pairs) - 1) < 1e-6, "Σp должно быть 1"
    return sum(p * v for p, v in pairs)
def variance(pairs):
    m = ev(pairs); return sum(p * (v - m) ** 2 for p, v in pairs)
lottery = [(1/1e7, 5_000_000), (1 - 1/1e7, -2)]   # билет за 2, шанс 1e-7 на 5 млн
check("E[лотерея] (отрицательная)", round(ev(lottery), 4), round(5_000_000/1e7 - 2*(1-1/1e7), 4))
bet = [(0.5, 100), (0.5, -100)]
check("E[честная монета]", ev(bet), 0.0)
check("Дисперсия честной ставки", variance(bet), 10000.0)
skewed = [(0.9, 10), (0.1, -100)]   # часто +10, редко -100
check("E[смещённая ставка]", round(ev(skewed), 2), round(0.9*10 - 0.1*100, 2))  # = -1.0

print("\n== Гл.3 · Байесовское обновление ==")
def bayes(prior, sens, spec):       # P(H|+) = posterior
    num = prior * sens
    den = num + (1 - prior) * (1 - spec)
    return num / den if den else 0.0
check("Posterior: prior 1%, sens 90%, spec 90%", round(bayes(0.01, 0.90, 0.90)*100, 2), 8.33)
check("Posterior: prior 50%, sens 90%, spec 90%", round(bayes(0.50, 0.90, 0.90)*100, 2), 90.0)
# монотонность: при росте prior posterior не убывает
seq = [bayes(p, 0.9, 0.9) for p in (0.01, 0.1, 0.5, 0.9)]
check("Монотонность posterior по prior", all(seq[i] <= seq[i+1] for i in range(3)), True)
def lr(sens, spec):                 # отношение правдоподобия для «+»
    return sens / (1 - spec)
check("Likelihood ratio (90/90)", lr(0.9, 0.9), 9.0)

print("\n== Гл.5 · Относительный ≠ абсолютный риск ==")
def risk(cer, eer):                 # cer/eer в долях
    arr = cer - eer
    rrr = arr / cer if cer else 0
    nnt = math.ceil(1/arr) if arr > 0 else None
    return arr, rrr, nnt
arr, rrr, nnt = risk(0.02, 0.01)     # 2% → 1%
check("ARR (2%→1%)", round(arr, 4), 0.01)
check("RRR (выглядит как 50%)", round(rrr, 2), 0.5)
check("NNT", nnt, 100)               # внушительные «−50%» = 1 на 100

print("\n== Гл.4 · Теория игр: дилемма заключённого (T>R>P>S) ==")
T, R, P, S = 5, 3, 1, 0              # классические выплаты
check("Порядок выплат T>R>P>S", T > R > P > S, True)
check("Кооперация (R+R) > взаимное предательство (P+P)", 2*R > 2*P, True)
# повторяющаяся игра: tit-for-tat против always-defect за n раундов
def iterated(strat_a, strat_b, n=10):
    a_hist, b_hist, a_sc, b_sc = [], [], 0, 0
    for _ in range(n):
        a = strat_a(a_hist, b_hist); b = strat_b(b_hist, a_hist)
        pay = {('C','C'):(R,R), ('C','D'):(S,T), ('D','C'):(T,S), ('D','D'):(P,P)}
        da, db = pay[(a, b)]; a_sc += da; b_sc += db
        a_hist.append(a); b_hist.append(b)
    return a_sc, b_sc
tft = lambda me, opp: 'C' if not opp else opp[-1]
alld = lambda me, opp: 'D'
allc = lambda me, opp: 'C'
check("TFT vs AllD: TFT не проигрывает катастрофически", iterated(tft, alld)[0] >= 0, True)
check("AllC vs AllC лучше, чем AllD vs AllD (для пары)", sum(iterated(allc, allc)) > sum(iterated(alld, alld)), True)

print("\n== Гл.2 · Комбинаторика и редкие события ==")
def C(n, k): return math.comb(n, k)
check("C(49,6) — лото 6 из 49", C(49, 6), 13_983_816)
check("P(джекпот) ≈ 1 / 14 млн", round(1/C(49, 6) * 1e7, 3), round(1e7/13_983_816, 3))
check("C(52,5) — покерные руки", C(52, 5), 2_598_960)

print("\n== Гл.5 · Доверительный интервал доли (Wald, для интуиции) ==")
def ci_prop(p, n, z=1.96):
    se = math.sqrt(p*(1-p)/n); return (p - z*se, p + z*se)
lo, hi = ci_prop(0.5, 100)
check("CI(50%, n=100) ширина ~0.196", round(hi - lo, 3), round(2*1.96*math.sqrt(0.25/100), 3))
lo2, hi2 = ci_prop(0.5, 1000)
check("Больше n → уже интервал", (hi2 - lo2) < (hi - lo), True)

print("\n== Гл.6 · Дерево решений (ожидаемая ценность ветвей) ==")
# выбор: гарантированно 50 vs ставка (0.5×120, 0.5×0)
safe = 50.0
gamble = ev([(0.5, 120), (0.5, 0)])
check("E[ставка] = 60", gamble, 60.0)
check("Рационально по EV: ставка > гарантия", gamble > safe, True)

print(f"\n✅ Все проверки пройдены: {ok}. Формулы курса корректны и готовы к переносу в JS.")
