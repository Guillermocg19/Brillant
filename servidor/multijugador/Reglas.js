// Port de reglas.dart. Cada regla recibe los números ya colocados en la zona
// y el número que se quiere colocar.

const reglas = {
  // Rojo y amarillo: "todos diferentes".
  rojo: (nums, n) => !nums.includes(n),
  amarillo: (nums, n) => !nums.includes(n),
  // Verde: "cualquiera".
  verde: () => true,
  // Azul y gris: "todos iguales" (zona vacía: cualquier número).
  azul: (nums, n) => nums.every((x) => x === n),
  gris: (nums, n) => nums.every((x) => x === n),
  // Morado: como máximo dos valores distintos por zona.
  morado: (nums, n) => {
    const distintos = new Set(nums);
    return distintos.has(n) || distintos.size < 2;
  },
  // Naranjas del nivel 4.
  naranjaAlto: (_nums, n) => n >= 4 && n <= 6,
  naranjaBajo: (_nums, n) => n >= 1 && n <= 3,
};

export function reglaParaColor(color) {
  const regla = reglas[color];
  if (!regla) throw new Error(`Color sin regla: ${color}`);
  return regla;
}