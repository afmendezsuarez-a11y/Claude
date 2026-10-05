# Apéndice A · Demostraciones extendidas

Reúne las pruebas largas referenciadas en el cuerpo del manual, más varias que no caben en ningún capítulo pero que todo doctorando debería haber hecho al menos una vez a mano.

**Índice**
1. [Integrabilidad (Hurwicz–Uzawa)](#a1)
2. [Lema de Shephard e identidad de Roy](#a2)
3. [Propiedades de la matriz de Slutsky](#a3)
4. [Excedente exacto de Hausman](#a4)
5. [Agregación de Gorman y PIGLOG](#a5)
6. [Equivalencia CES ↔ Logit](#a6)
7. [Verificación de las condiciones GEV](#a7)
8. [Momentos de la distribución Gumbel](#a8)
9. [Concavidad global de la verosimilitud logit](#a9)
10. [Markup multiproducto: forma matricial completa](#a10)
11. [Pass-through y curvatura de la demanda](#a11)
12. [Equivalencia de ingresos en subastas](#a12)
13. [Identificación GPV](#a13)
14. [Condición de sostenibilidad de la colusión con castigos óptimos](#a14)
15. [Sesgo asintótico de 2SLS con instrumentos débiles](#a15)

---

<a name="a1"></a>
## A1. Integrabilidad: de la demanda a las preferencias

**Teorema.** Sea $q(p,X):\mathbb{R}^{n+1}_{++}\to\mathbb{R}^n_+$ continuamente diferenciable que satisface:
(i) homogeneidad de grado 0; (ii) adding-up $p'q(p,X)=X$; (iii) la matriz de Slutsky $S(p,X)$ con elementos $s_{ij}=\partial q_i/\partial p_j + q_j\,\partial q_i/\partial X$ es **simétrica** y **semidefinida negativa**.
Entonces existe una función de utilidad continua, creciente y cuasicóncava que genera $q$.

**Demostración.**

**Paso 1 — El sistema de EDP.** Buscamos $e(p)$ (fijando un nivel de utilidad de referencia) tal que
$$\frac{\partial e(p)}{\partial p_i}=q_i\big(p, e(p)\big),\qquad i=1,\dots,n, \qquad e(p^0)=X^0 \tag{A1.1}$$

Este es un sistema de $n$ EDP de primer orden en una función desconocida, con la peculiaridad de que la propia incógnita $e$ aparece en el lado derecho (es cuasi-lineal).

**Paso 2 — Condición de integrabilidad de Frobenius.** Para que (A1.1) tenga solución se requiere la igualdad de las derivadas cruzadas:
$$\frac{\partial^2 e}{\partial p_j\partial p_i}=\frac{\partial^2 e}{\partial p_i\partial p_j}$$

Calculando el lado izquierdo a partir de (A1.1) y usando la regla de la cadena (recordando que $e$ depende de $p_j$):
$$\frac{\partial}{\partial p_j}\Big[q_i(p,e(p))\Big]=\frac{\partial q_i}{\partial p_j}+\frac{\partial q_i}{\partial X}\cdot\frac{\partial e}{\partial p_j}=\frac{\partial q_i}{\partial p_j}+q_j\frac{\partial q_i}{\partial X}=s_{ij}$$

Análogamente, la derivada en el otro orden da $s_{ji}$. Por tanto la condición de Frobenius es **exactamente** $s_{ij}=s_{ji}$: la **simetría de Slutsky**. $\checkmark$

**Paso 3 — Existencia local.** Por el teorema de Frobenius, con la condición de simetría y la diferenciabilidad continua de $q$, existe una solución local única $e(p)$ en un entorno de $p^0$. La homogeneidad de grado 0 de $q$ más adding-up permiten extender la solución globalmente sobre $\mathbb{R}^n_{++}$ (la homogeneidad implica que basta resolver sobre el simplex de precios normalizados).

**Paso 4 — Propiedades de $e$.** 
- *Creciente:* $\partial e/\partial p_i=q_i\ge 0$. $\checkmark$
- *Homogénea de grado 1:* por el teorema de Euler, $\sum_i p_i\,\partial e/\partial p_i=\sum_i p_i q_i=e$ (por adding-up), que es la caracterización de homogeneidad de grado 1. $\checkmark$
- *Cóncava:* la Hessiana de $e$ tiene elementos $\partial^2 e/\partial p_i\partial p_j = s_{ij}$, que es la matriz de Slutsky. Por hipótesis (iii) es semidefinida negativa, luego $e$ es cóncava. $\checkmark$

**Paso 5 — Recuperar la utilidad.** Toda función homogénea de grado 1, creciente y cóncava en $p$ es la función de soporte de un conjunto convexo. Definimos
$$U(q)=\min_{p\in\mathbb{R}^n_{++}}\big\{u : e(p,u)\le p'q\big\}$$
Esta función es continua, creciente y cuasicóncava, y por dualidad genera $e(p,u)$ como su función de gasto y, por Shephard, $q(p,X)$ como su demanda Marshalliana. $\blacksquare$

**Comentario.** El teorema establece que las condiciones de simetría y negatividad no son "chequeos de calidad" opcionales: son **necesarias y suficientes** para que el sistema estimado tenga interpretación de preferencias. Un AIDS que las viola no permite ningún cálculo de bienestar.

---

<a name="a2"></a>
## A2. Lema de Shephard e identidad de Roy

### A2.1 Lema de Shephard

**Enunciado.** $\dfrac{\partial e(p,u)}{\partial p_i}=h_i(p,u)$.

**Demostración (vía teorema de la envolvente).** Por definición,
$$e(p,u)=\min_q\{p'q : U(q)\ge u\} = p'h(p,u)$$

Diferenciando totalmente respecto de $p_i$:
$$\frac{\partial e}{\partial p_i}=h_i(p,u)+\sum_j p_j\frac{\partial h_j}{\partial p_i}$$

El segundo término es cero. Razón: la restricción $U(h(p,u))=u$ se mantiene idénticamente, así que diferenciando,
$$\sum_j \frac{\partial U}{\partial q_j}\frac{\partial h_j}{\partial p_i}=0$$
Y en el óptimo, las CPO del problema de minimización dan $\partial U/\partial q_j=p_j/\lambda$ para un multiplicador $\lambda>0$. Sustituyendo:
$$\frac{1}{\lambda}\sum_j p_j\frac{\partial h_j}{\partial p_i}=0\ \Longrightarrow\ \sum_j p_j\frac{\partial h_j}{\partial p_i}=0$$
Por tanto $\partial e/\partial p_i=h_i$. $\blacksquare$

**Intuición:** al cambiar $p_i$ marginalmente, el ajuste óptimo de las cantidades tiene un efecto de **segundo orden** sobre el costo (porque estábamos en un óptimo). El efecto de primer orden es solo el cambio mecánico de precio sobre la cantidad que ya se compraba.

### A2.2 Identidad de Roy

**Enunciado.** $q_i(p,X)=-\dfrac{\partial v/\partial p_i}{\partial v/\partial X}$.

**Demostración.** De la identidad de dualidad $v(p, e(p,u))=u$, diferenciando respecto de $p_i$:
$$\frac{\partial v}{\partial p_i}+\frac{\partial v}{\partial X}\cdot\frac{\partial e}{\partial p_i}=0$$
Por Shephard, $\partial e/\partial p_i=h_i=q_i$ (evaluados en el óptimo). Despejando:
$$q_i=-\frac{\partial v/\partial p_i}{\partial v/\partial X}\qquad\blacksquare$$

---

<a name="a3"></a>
## A3. Propiedades de la matriz de Slutsky

**Proposición.** La matriz $S$ con $s_{ij}=\partial h_i/\partial p_j$ satisface: (a) simetría, (b) semidefinida negativa, (c) $S\,p=0$.

**(a) Simetría.** $s_{ij}=\partial h_i/\partial p_j = \partial^2 e/\partial p_j\partial p_i$ por Shephard. Por el teorema de Young (igualdad de derivadas cruzadas de una función $C^2$), $=\partial^2 e/\partial p_i\partial p_j = s_{ji}$. $\blacksquare$

**(b) Semidefinida negativa.** $S$ es la Hessiana de $e(\cdot,u)$. Como $e$ es cóncava en $p$ (es un mínimo de funciones lineales en $p$, y el mínimo puntual de funciones cóncavas —aquí, lineales— es cóncavo), su Hessiana es semidefinida negativa. $\blacksquare$

**Corolario (ley de demanda compensada):** $s_{ii}=\partial h_i/\partial p_i\le 0$. **Las demandas Hicksianas siempre tienen pendiente negativa.** Las Marshallianas pueden no tenerla (bienes Giffen) porque el efecto ingreso puede dominar.

**(c) $Sp=0$.** Por homogeneidad de grado 0 de $h$ en $p$ y el teorema de Euler: $\sum_j p_j\,\partial h_i/\partial p_j = 0$ para todo $i$. $\blacksquare$

**Consecuencia:** $S$ tiene rango a lo sumo $n-1$ y siempre tiene un autovalor cero (con autovector $p$). **Por eso en el test de negatividad del Cap. 01 §2.3 se espera un autovalor nulo** y todos los demás estrictamente negativos.

---

<a name="a4"></a>
## A4. Excedente exacto de Hausman

Para una demanda Marshalliana estimada $q=f(p,X)$, el gasto compensado resuelve
$$\frac{\partial e}{\partial p}=f\big(p, e(p)\big),\qquad e(p^0)=X \tag{A4.1}$$

### Caso log-lineal
Con $\ln q = \alpha+\beta\ln p+\gamma\ln X$, es decir $q = e^{\alpha}p^{\beta}X^{\gamma}$:
$$\frac{de}{dp}=e^{\alpha}p^{\beta}e^{\gamma}\ \Longrightarrow\ e^{-\gamma}\,de = e^{\alpha}p^{\beta}\,dp$$

Integrando de $p_0$ a $p_1$:
$$\frac{e^{1-\gamma}}{1-\gamma}\bigg|_{X}^{e(p_1)}=\frac{e^{\alpha}p^{1+\beta}}{1+\beta}\bigg|_{p_0}^{p_1}$$

$$\boxed{\ e(p_1)=\left[X^{1-\gamma}+\frac{(1-\gamma)\,e^{\alpha}}{1+\beta}\big(p_1^{1+\beta}-p_0^{1+\beta}\big)\right]^{\frac{1}{1-\gamma}}\ }$$

y $CV = e(p_1)-X$. Requiere $\gamma\ne 1$ y $\beta\ne -1$ (los casos límite se obtienen tomando límites, con logaritmos).

### Caso sin efecto ingreso ($\gamma=0$)
$$CV=\frac{e^{\alpha}}{1+\beta}\big(p_1^{1+\beta}-p_0^{1+\beta}\big)$$
que coincide con el excedente del consumidor marshalliano (integral bajo la demanda), como debe ser.

---

<a name="a5"></a>
## A5. Gorman y PIGLOG

### A5.1 Gorman polar: suficiencia

Si $v_h(p,X_h)=\dfrac{X_h-a_h(p)}{b(p)}$, por Roy:
$$q_{ih}=-\frac{\partial v_h/\partial p_i}{\partial v_h/\partial X_h}$$

Calculamos:
$$\frac{\partial v_h}{\partial X_h}=\frac{1}{b(p)},\qquad \frac{\partial v_h}{\partial p_i}=\frac{-\partial_i a_h\cdot b - (X_h-a_h)\partial_i b}{b^2}$$

Por tanto:
$$q_{ih}=\frac{\partial_i a_h\cdot b+(X_h-a_h)\partial_i b}{b^2}\cdot b=\partial_i a_h+\frac{\partial_i b}{b}(X_h-a_h)$$

La derivada respecto del gasto es $\partial q_{ih}/\partial X_h = \partial_i b/b$, **idéntica para todos los hogares** porque $b$ es común. Agregando:
$$Q_i=\sum_h q_{ih}=\sum_h \partial_i a_h - \frac{\partial_i b}{b}\sum_h a_h + \frac{\partial_i b}{b}\,X$$
que depende de $\{X_h\}$ solo vía $X=\sum_h X_h$. $\blacksquare$

### A5.2 PIGLOG y el nivel de gasto representativo

Con $\ln e(u,p)=(1-u)\ln a(p)+u\ln b(p)$, las participaciones individuales son lineales en $\ln X_h$:
$$w_{ih}=\alpha_i+\sum_j\gamma_{ij}\ln p_j+\beta_i\big(\ln X_h-\ln a(p)\big)$$

Agregando sobre hogares con ponderación por gasto:
$$W_i \equiv \frac{\sum_h p_iq_{ih}}{\sum_h X_h}=\sum_h \frac{X_h}{X}w_{ih}=\alpha_i+\sum_j\gamma_{ij}\ln p_j+\beta_i\Big(\underbrace{\sum_h\frac{X_h}{X}\ln X_h}_{\ln X^*}-\ln a(p)\Big)$$

donde $\ln X^*=\sum_h (X_h/X)\ln X_h$ es el **nivel de gasto representativo** (la media logarítmica ponderada por gasto). La ecuación agregada tiene **exactamente la misma forma** que la individual, con $X^*$ en lugar de $X_h$. $\blacksquare$

**Consecuencia práctica:** si la distribución del gasto es estable, $\ln X^* \approx \ln \bar X + \text{const}$, y estimar con el gasto medio introduce solo un desplazamiento en la constante $\alpha_i$. Si la distribución cambia (como ocurrió en Perú entre 2004 y 2019), la agregación introduce sesgo. **Es otra razón para preferir microdatos sobre agregados.**

---

<a name="a6"></a>
## A6. Equivalencia CES ↔ Logit

Esta equivalencia explica por qué la log-lineal (Cap. 03) tiene el mismo problema de IIA que el logit (Cap. 05), y rara vez se enuncia.

**Setup CES.** Preferencias sobre $J$ variedades:
$$U=\Big[\sum_{j=1}^{J}a_j\,q_j^{\frac{\sigma-1}{\sigma}}\Big]^{\frac{\sigma}{\sigma-1}},\qquad \sigma>1$$

La demanda es:
$$q_j=a_j^{\sigma}\,p_j^{-\sigma}\,P^{\sigma-1}X,\qquad P=\Big[\sum_k a_k^{\sigma}p_k^{1-\sigma}\Big]^{\frac{1}{1-\sigma}}$$

**Participación de gasto:**
$$w_j=\frac{p_jq_j}{X}=\frac{a_j^\sigma p_j^{1-\sigma}}{\sum_k a_k^\sigma p_k^{1-\sigma}}$$

**Reparametrizando.** Sea $\delta_j \equiv \sigma\ln a_j+(1-\sigma)\ln p_j$. Entonces
$$\boxed{\ w_j=\frac{e^{\delta_j}}{\sum_k e^{\delta_k}}\ }$$

**Es exactamente la fórmula logit**, con $\delta_j$ lineal en $\ln p_j$ con coeficiente $(1-\sigma)$ en lugar de lineal en $p_j$.

**Consecuencias:**
1. **CES tiene IIA:** $w_j/w_k=e^{\delta_j-\delta_k}$ no depende de las otras variedades. La log-lineal hereda este problema.
2. **La elasticidad propia CES es** $\varepsilon_{jj}=-\sigma(1-w_j)-w_j \approx -\sigma$ para $w_j$ pequeño. **La "elasticidad constante" de la log-lineal es la elasticidad de sustitución CES.**
3. **Agregando la decisión de "comprar o no" con un bien externo**, CES y logit son el mismo modelo con reparametrización. La diferencia práctica es si el precio entra en niveles ($-\alpha p$, logit) o en logs ($(1-\sigma)\ln p$, CES). **Esto afecta el pass-through de forma material** (Cap. 07 §4.2): con logit el pass-through es ~1; con CES es $>1$.

---

<a name="a7"></a>
## A7. Verificación de las condiciones GEV para el nested logit

**La función generadora:**
$$G(y)=\sum_{g=1}^{G}\Big(\sum_{j\in g}y_j^{1/(1-\sigma)}\Big)^{1-\sigma},\qquad \sigma\in[0,1)$$

**Condición 1 — no negatividad.** Obvio para $y\ge 0$. $\checkmark$

**Condición 2 — homogeneidad de grado 1.** 
$$G(\lambda y)=\sum_g\Big(\sum_{j\in g}(\lambda y_j)^{1/(1-\sigma)}\Big)^{1-\sigma}=\sum_g\Big(\lambda^{1/(1-\sigma)}\sum_{j\in g}y_j^{1/(1-\sigma)}\Big)^{1-\sigma}=\lambda\,G(y)\ \checkmark$$

**Condición 3 — no acotada.** Si $y_j\to\infty$ para algún $j$, el término de su nido diverge. $\checkmark$

**Condición 4 — signos alternados de las derivadas cruzadas.** Sea $A_g=\sum_{j\in g}y_j^{1/(1-\sigma)}$ y $\rho\equiv 1/(1-\sigma)>1$.

Primera derivada ($j\in g$):
$$G_j=\frac{\partial G}{\partial y_j}=(1-\sigma)A_g^{-\sigma}\cdot\rho\, y_j^{\rho-1}=A_g^{-\sigma}y_j^{\rho-1}>0\ \checkmark$$

Segunda derivada cruzada dentro del mismo nido ($j\ne k$, ambos en $g$):
$$G_{jk}=\frac{\partial^2 G}{\partial y_j\partial y_k}=-\sigma A_g^{-\sigma-1}\rho\,y_k^{\rho-1}y_j^{\rho-1}=-\sigma\rho\,A_g^{-\sigma-1}(y_jy_k)^{\rho-1}\le 0\ \checkmark$$

(Se requiere $\sigma\ge 0$; con $\sigma<0$ el signo se invierte y la condición falla — **ésta es la razón formal de la restricción $\sigma\ge0$.**)

Entre nidos distintos, $G_{jk}=0$, que satisface trivialmente la condición de signo. Las derivadas de orden superior siguen el patrón alternado por inducción sobre los factores $(-\sigma)(-\sigma-1)\cdots$ en la cadena de diferenciación de $A_g^{-\sigma}$.

**Nota:** con $\sigma\to 1$, $\rho\to\infty$ y la función se degenera (todos los productos del nido se vuelven perfectos sustitutos); con $\sigma=0$, $G=\sum_j y_j$ y recuperamos el logit simple. $\blacksquare$

---

<a name="a8"></a>
## A8. Momentos de la Gumbel

$F(\varepsilon)=\exp(-e^{-\varepsilon})$, $f(\varepsilon)=e^{-\varepsilon}\exp(-e^{-\varepsilon})$.

**Media.** Con el cambio de variable $u=e^{-\varepsilon}$ (de donde $\varepsilon=-\ln u$, $d\varepsilon=-du/u$):
$$E[\varepsilon]=\int_{-\infty}^{\infty}\varepsilon\,e^{-\varepsilon}e^{-e^{-\varepsilon}}d\varepsilon=\int_0^\infty(-\ln u)\,e^{-u}\,du=-\Gamma'(1)=\gamma\approx 0.5772$$

(donde se usa $\Gamma'(1)=-\gamma$, la constante de Euler–Mascheroni.)

**Varianza.** Análogamente, $E[\varepsilon^2]=\Gamma''(1)=\gamma^2+\pi^2/6$, de donde $\text{Var}(\varepsilon)=\pi^2/6\approx 1.645$. $\blacksquare$

**Diferencia de dos Gumbel es logística.** Sean $\varepsilon_1,\varepsilon_2$ i.i.d. Gumbel. Entonces
$$\Pr(\varepsilon_2-\varepsilon_1\le z)=\int F(e+z)f(e)\,de=\int \exp(-e^{-(e+z)})e^{-e}\exp(-e^{-e})de$$
Con $u=e^{-e}$:
$$=\int_0^\infty \exp(-u e^{-z})e^{-u}du=\int_0^\infty e^{-u(1+e^{-z})}du=\frac{1}{1+e^{-z}}=\Lambda(z)\qquad\blacksquare$$

**Esto es exactamente por qué el caso binario del RUM es la regresión logística.**

**Máximo de Gumbels es Gumbel.** Con localizaciones $V_j$:
$$\Pr\big(\max_j(V_j+\varepsilon_j)\le x\big)=\prod_j\exp\big(-e^{-(x-V_j)}\big)=\exp\Big(-e^{-x}\sum_je^{V_j}\Big)=\exp\Big(-e^{-(x-\ln\sum_je^{V_j})}\Big)$$
Gumbel con localización $\ln\sum_j e^{V_j}$. De aquí sale el **log-sum** del Cap. 05 §6.1. $\blacksquare$

---

<a name="a9"></a>
## A9. Concavidad global de la verosimilitud logit

**Proposición (McFadden 1974).** La log-verosimilitud del logit condicional es globalmente cóncava en $\beta$.

**Demostración.**
$$\ln L(\beta)=\sum_{i}\sum_j d_{ij}\Big[x_{ij}'\beta-\ln\sum_k e^{x_{ik}'\beta}\Big]$$

Gradiente:
$$\frac{\partial \ln L}{\partial\beta}=\sum_i\sum_j d_{ij}\big(x_{ij}-\bar x_i\big),\qquad \bar x_i\equiv\sum_k P_{ik}x_{ik}$$

Hessiana:
$$\frac{\partial^2\ln L}{\partial\beta\partial\beta'}=-\sum_i\sum_k P_{ik}\big(x_{ik}-\bar x_i\big)\big(x_{ik}-\bar x_i\big)'$$

Para cualquier vector $z\ne 0$:
$$z'\,H\,z=-\sum_i\sum_k P_{ik}\Big[z'(x_{ik}-\bar x_i)\Big]^2\ \le 0$$

Es la negativa de una suma ponderada de cuadrados, con pesos $P_{ik}>0$. Por tanto $H$ es semidefinida negativa en todo el dominio, y es **definida** negativa salvo colinealidad perfecta de los regresores (en cuyo caso $\beta$ no está identificado). $\blacksquare$

**Consecuencias prácticas:** (i) el máximo es único; (ii) Newton–Raphson converge desde cualquier punto inicial; (iii) **no hay que preocuparse por óptimos locales en el logit simple**. Nada de esto vale para mixed logit ni para BLP, donde la función objetivo **no** es cóncava — de ahí la necesidad de multi-start (Cap. 06 §4.5).

---

<a name="a10"></a>
## A10. Markup multiproducto: la forma matricial

Sea $\mathcal{F}_f$ el conjunto de productos de la firma $f$, $\boldsymbol p$ el vector de precios, $\boldsymbol s(\boldsymbol p)$ el vector de participaciones, $M$ el tamaño de mercado.

$$\Pi_f=M\sum_{j\in\mathcal F_f}(p_j-c_j)s_j(\boldsymbol p)$$

CPO para $k\in\mathcal F_f$:
$$s_k+\sum_{j\in\mathcal F_f}(p_j-c_j)\frac{\partial s_j}{\partial p_k}=0$$

Definimos $\Delta_{jk}=\partial s_j/\partial p_k$ y $H_{jk}=\mathbf{1}\{j,k \text{ misma firma}\}$. La suma restringida a $\mathcal F_f$ se escribe, para todo $k$ y toda firma simultáneamente, como
$$s_k+\sum_{j=1}^{J}H_{jk}\,\Delta_{jk}\,(p_j-c_j)=0$$

En forma vectorial, la fila $k$ del sistema tiene coeficientes $\{H_{jk}\Delta_{jk}\}_j$, es decir, el vector $(\boldsymbol\Delta\odot\boldsymbol H)$ transpuesto aplicado a $(\boldsymbol p-\boldsymbol c)$:
$$\boldsymbol s + (\boldsymbol\Delta\odot\boldsymbol H)'(\boldsymbol p-\boldsymbol c)=\boldsymbol 0$$

$$\boxed{\boldsymbol p-\boldsymbol c = -\big[(\boldsymbol\Delta\odot\boldsymbol H)'\big]^{-1}\boldsymbol s}$$

**Existencia de la inversa:** $\boldsymbol\Delta$ es estrictamente diagonal dominante en demanda logit (la derivada propia domina la suma de las cruzadas, porque la suma de las derivadas de la fila es $-\alpha s_j s_0 < 0$ estrictamente cuando hay bien externo). Por el teorema de Levy–Desplanques, la matriz es no singular. **De nuevo, el bien externo es lo que garantiza que el problema esté bien planteado.** $\blacksquare$

### Caso logit multiproducto, resuelto

Con $\Delta_{jj}=-\alpha s_j(1-s_j)$ y $\Delta_{jk}=\alpha s_js_k$, conjeturamos que el markup es común a todos los productos de la firma, $p_j-c_j=m_f$. Sustituyendo en la CPO:
$$s_k + m_f\Big[-\alpha s_k(1-s_k)+\sum_{j\in\mathcal F_f, j\ne k}\alpha s_js_k\Big]=0$$
$$s_k+m_f\,\alpha s_k\Big[-(1-s_k)+\sum_{j\in\mathcal F_f,j\ne k}s_j\Big]=0$$
$$1+m_f\,\alpha\Big[-1+s_k+S_f-s_k\Big]=0,\qquad S_f\equiv\sum_{j\in\mathcal F_f}s_j$$
$$\boxed{m_f=\frac{1}{\alpha(1-S_f)}}$$

La conjetura es consistente: el markup es el mismo para todos los productos de la firma y depende solo de la participación **total** de la firma. $\blacksquare$

---

<a name="a11"></a>
## A11. Pass-through y curvatura

Monopolista con costo marginal constante $c$ y demanda $q(p)$. CPO:
$$q(p)+(p-c)q'(p)=0 \tag{A11.1}$$

Diferenciando totalmente respecto de $c$:
$$q'\frac{dp}{dc}+\Big(\frac{dp}{dc}-1\Big)q'+(p-c)q''\frac{dp}{dc}=0$$
$$\frac{dp}{dc}\Big[2q'+(p-c)q''\Big]=q'$$
$$\rho=\frac{dp}{dc}=\frac{q'}{2q'+(p-c)q''}$$

De (A11.1), $(p-c)=-q/q'$. Sustituyendo:
$$\rho=\frac{q'}{2q'-\frac{q}{q'}q''}=\frac{1}{2-\frac{q\,q''}{(q')^2}}=\boxed{\frac{1}{2-\kappa}},\qquad \kappa\equiv\frac{q\,q''}{(q')^2}$$

**Casos:**

*Lineal:* $q=a-bp$, $q''=0$ ⇒ $\kappa=0$ ⇒ $\rho=1/2$.

*Elasticidad constante:* $q=Ap^{-\eta}$. Entonces $q'=-\eta Ap^{-\eta-1}$, $q''=\eta(\eta+1)Ap^{-\eta-2}$:
$$\kappa=\frac{Ap^{-\eta}\cdot\eta(\eta+1)Ap^{-\eta-2}}{\eta^2A^2p^{-2\eta-2}}=\frac{\eta+1}{\eta}$$
$$\rho=\frac{1}{2-\frac{\eta+1}{\eta}}=\frac{\eta}{2\eta-\eta-1}=\frac{\eta}{\eta-1}>1$$

**Sobre-traslado confirmado.** Con $\eta=2$, $\rho=2$: un aumento de costo de S/1 sube el precio en S/2. $\blacksquare$

*Exponencial:* $q=Ae^{-bp}$ ⇒ $q'=-bq$, $q''=b^2q$ ⇒ $\kappa = q\cdot b^2q/(b^2q^2)=1$ ⇒ $\rho=1$.

---

<a name="a12"></a>
## A12. Equivalencia de ingresos

**Setup.** $n$ postores, valores i.i.d. $v\sim F$ en $[0,\bar v]$, neutralidad al riesgo. Consideramos cualquier mecanismo directo incentivo-compatible que asigne el objeto al postor de mayor valor.

**Paso 1 — Utilidad esperada.** Sea $U(v)$ el excedente esperado de un postor con valor $v$ que reporta la verdad, y $\pi(v)=F(v)^{n-1}$ su probabilidad de ganar.

Por incentivo-compatibilidad, $U(v)=\max_z\{v\,\pi(z)-m(z)\}$ donde $m(z)$ es el pago esperado. Por el **teorema de la envolvente** (Milgrom–Segal):
$$U'(v)=\frac{\partial}{\partial v}\big[v\pi(z)-m(z)\big]\bigg|_{z=v}=\pi(v)=F(v)^{n-1}$$

**Paso 2 — Integrar.**
$$U(v)=U(0)+\int_0^v F(y)^{n-1}dy$$

Con la condición de frontera $U(0)=0$ (el postor de valor mínimo no obtiene excedente — supuesto (v)):
$$U(v)=\int_0^v F(y)^{n-1}dy$$

**Paso 3 — Pago esperado.** De $U(v)=v\,F(v)^{n-1}-m(v)$:
$$m(v)=v\,F(v)^{n-1}-\int_0^v F(y)^{n-1}dy$$

**Esta expresión no contiene ninguna referencia al formato de la subasta.** Depende solo de $F$, $n$ y de los dos supuestos usados (asignación eficiente, $U(0)=0$).

**Paso 4 — Ingreso esperado.**
$$R=n\int_0^{\bar v}m(v)\,f(v)\,dv$$
que es el mismo para todo formato que satisfaga los supuestos. $\blacksquare$

**La estrategia de primer precio como corolario.** En primer precio, $m(v)=b(v)F(v)^{n-1}$ (paga su puja solo si gana). Igualando:
$$b(v)F(v)^{n-1}=vF(v)^{n-1}-\int_0^vF(y)^{n-1}dy$$
$$\boxed{b(v)=v-\frac{\int_0^vF(y)^{n-1}dy}{F(v)^{n-1}}}$$

que es la fórmula del Cap. 08 §5.2, obtenida ahora sin resolver la EDO. $\blacksquare$

---

<a name="a13"></a>
## A13. Identificación GPV

**Setup (subasta inversa de compras, primer precio).** $n$ postores, costos privados $c\sim F_c$ i.i.d., gana el de menor puja y cobra su puja.

**Paso 1 — Equilibrio.** El postor con costo $c$ que puja $b$ gana si todos los demás pujan más. Sea $G$ la distribución de una puja de un rival y $H(b)=[1-G(b)]^{n-1}$ la probabilidad de ganar con la puja $b$.

$$\max_b\ (b-c)\,[1-G(b)]^{n-1}$$

CPO:
$$[1-G(b)]^{n-1}-(b-c)(n-1)[1-G(b)]^{n-2}g(b)=0$$

Despejando $c$:
$$\boxed{\ c = b - \frac{1-G(b)}{(n-1)\,g(b)}\ } \tag{A13.1}$$

**Paso 2 — El argumento de identificación.** El lado derecho de (A13.1) contiene **únicamente** la distribución de las pujas observadas $G$ y su densidad $g$, más el número de postores $n$, todos observables. Por tanto, para cada puja observada $b_i$, el costo subyacente $c_i$ es **identificado puntualmente**.

**Paso 3 — Recuperar $F_c$.** Como el mapa $b\mapsto c$ es estrictamente creciente (bajo regularidad), la distribución de los pseudo-costos $\{c_i\}$ es consistente para $F_c$.

**Conclusión:** $F_c$ está identificada **no paramétricamente** a partir de la distribución observada de pujas. No se requiere ninguna forma funcional. $\blacksquare$

**Estimación en dos pasos (GPV 2000):**
$$\hat G(b)=\frac{1}{L n}\sum_{\ell,i}\mathbf{1}\{b_{i\ell}\le b\},\qquad \hat g(b)=\frac{1}{Lnh}\sum_{\ell,i}K\Big(\frac{b-b_{i\ell}}{h}\Big)$$
$$\hat c_{i\ell}=b_{i\ell}-\frac{1-\hat G(b_{i\ell})}{(n_\ell-1)\hat g(b_{i\ell})}$$
y luego un kernel sobre $\{\hat c_{i\ell}\}$ para $\hat F_c$.

**Tasa de convergencia:** $\hat F_c$ converge a la tasa no paramétrica óptima $n^{-\frac{R}{2R+3}}$ donde $R$ es el orden de suavidad de $F_c$ — más lenta que $\sqrt n$, que es el precio de no imponer forma funcional.

**Trimming:** el estimador es inconsistente dentro de una banda de ancho $h$ de los extremos del soporte (sesgo de frontera del kernel). GPV recomiendan descartar esas observaciones.

---

<a name="a14"></a>
## A14. Sostenibilidad de la colusión con castigos óptimos

**Estrategia de gatillo (Friedman).** Con $N$ firmas simétricas, beneficios $\pi^M/N$ (colusión), $\pi^D$ (desviación), $\pi^N$ (Nash estático):
$$\frac{\pi^M/N}{1-\delta}\ \ge\ \pi^D+\frac{\delta\pi^N}{1-\delta}$$
$$\boxed{\ \delta\ \ge\ \delta^{\text{trigger}}=\frac{\pi^D-\pi^M/N}{\pi^D-\pi^N}\ }$$

**Caso Bertrand homogéneo:** $\pi^D=\pi^M$, $\pi^N=0$ ⇒ $\delta\ge (N-1)/N$.

**Caso Cournot:** $\pi^N>0$ (el Nash de Cournot da beneficios positivos), lo que **relaja** la restricción (el castigo es menos severo pero la desviación también es menos atractiva). El efecto neto depende de los parámetros.

**Castigo óptimo (Abreu).** En lugar de Nash para siempre, el castigo óptimo es el que minimiza el valor de continuación del desviador sujeto a ser él mismo creíble (subgame perfect). Abreu (1986) muestra que tiene la estructura "palo y zanahoria":
- Una fase de castigo de un periodo con beneficio $\underline\pi < \pi^N$ (precio por debajo del costo).
- Retorno a la colusión después.

Dos restricciones de incentivos:
$$\text{(IC colusión)}\quad \frac{\pi^M/N}{1-\delta}\ge \pi^D + \delta\Big[\underline\pi+\frac{\delta\,\pi^M/N}{1-\delta}\Big]$$
$$\text{(IC castigo)}\quad \underline\pi+\frac{\delta\,\pi^M/N}{1-\delta}\ \ge\ \pi^{D}(\underline\pi)+\delta\Big[\underline\pi+\frac{\delta\pi^M/N}{1-\delta}\Big]$$

La segunda garantiza que las firmas efectivamente ejecuten el castigo. El $\delta$ crítico resultante es **estrictamente menor** que $\delta^{\text{trigger}}$. $\blacksquare$

**Implicación empírica (Cap. 09):** observar un episodio de precios por debajo del costo es consistente con la fase de castigo de un cartel **y** con predación. Distinguirlos requiere evidencia adicional (quién baja, contra quién, qué pasa después).

---

<a name="a15"></a>
## A15. Sesgo asintótico de 2SLS con instrumentos débiles

**Setup.** Modelo con un endógeno:
$$y = \beta x + u,\qquad x = \pi' z + v,\qquad \text{Corr}(u,v)=\rho$$

**El estimador:**
$$\hat\beta_{2SLS}-\beta = \frac{x'P_zu}{x'P_zx}$$

**Asintótica de muestras grandes (estándar):** con $\pi$ fijo y $T\to\infty$, el sesgo tiende a cero.

**Asintótica de instrumentos débiles (Staiger–Stock 1997):** modelar $\pi = C/\sqrt T$, de modo que la fuerza del instrumento no crece con la muestra. Entonces el "concentration parameter" $\mu^2 = \pi'Z'Z\pi/\sigma_v^2$ converge a una constante, y:

$$\hat\beta_{2SLS}-\beta\ \xrightarrow{d}\ \frac{\rho\,\sigma_u}{\sigma_v}\cdot\frac{(\text{forma cuadrática en normales})}{(\cdot)}$$

que **no** converge a cero. La aproximación de sesgo relativo:
$$\frac{E[\hat\beta_{2SLS}]-\beta}{E[\hat\beta_{OLS}]-\beta}\approx\frac{1}{\mu^2/K+1}\approx\frac{1}{F}$$

donde $K$ es el número de instrumentos y $F$ el estadístico de primera etapa.

**Casos límite:**
- $\pi=0$ exactamente: $\hat\beta_{2SLS}$ sigue una distribución **Cauchy** (cociente de dos normales). No tiene momentos. El test $t$ no tiene ningún significado asintótico.
- $F=10$: sesgo relativo ≈ 10%. De ahí la regla de dedo.
- Para **tamaño correcto del test al 5%**, Lee et al. (2022) muestran que se requiere $F>104.7$. La regla de 10 controla el sesgo puntual, no la cobertura de los intervalos. $\blacksquare$

**El test Anderson–Rubin, por contraste.** Bajo $H_0:\beta=\beta_0$, el residuo $y-\beta_0 x = u$ es ortogonal a $z$ **sea cual sea** $\pi$. El estadístico
$$AR(\beta_0)=\frac{(y-\beta_0x)'P_z(y-\beta_0x)/K}{(y-\beta_0x)'M_z(y-\beta_0x)/(T-K)}\ \sim\ F_{K,T-K}$$
tiene distribución exacta bajo normalidad y asintóticamente correcta en general, **independientemente de la fuerza del instrumento**. Esta robustez es la razón por la que es el estándar recomendado cuando $F$ es moderado.
