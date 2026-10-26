/// Bloque rojo/amarillo: "Todos diferentes".
/// Verifica si, al insertar [numero] en [numeros], no quedaría repetido.
bool cumpleTodosDiferentes(List<int> numeros, int numero) {
  return !numeros.contains(numero);
}

/// Bloque verde: "Cualquiera". No hay restricción, siempre se cumple.
bool cumpleVerde(List<int> numeros, int numero) {
  return true;
}

/// Bloque azul: "Todos iguales".
/// El número a insertar debe coincidir con todos los que ya están en la lista.
/// Si la lista está vacía, cualquier número la cumple (no hay nada que romper).
bool cumpleAzul(List<int> numeros, int numero) {
  if (numeros.isEmpty) return true;
  return numeros.every((n) => n == numero);
}

/// Bloque morado: "Solo dos números distintos por zona".
/// Se permite que la zona tenga como máximo 2 valores distintos entre sí;
/// el resto de las casillas debe repetir uno de esos 2 valores.
bool cumpleMorado(List<int> numeros, int numero) {
  final distintos = numeros.toSet();

  // Si el número ya es uno de los valores presentes, no suma un valor nuevo.
  if (distintos.contains(numero)) return true;

  // Si aún no se han usado 2 valores distintos, este puede ser el segundo.
  return distintos.length < 2;
}
/// Naranja "4-6": solo se permiten números del 4 al 6 (se pueden repetir).
bool cumpleNaranjaAlto(List<int> numeros, int numero) {
  return numero >= 4 && numero <= 6;
}

/// Naranja "1-3": solo se permiten números del 1 al 3 (se pueden repetir).
bool cumpleNaranjaBajo(List<int> numeros, int numero) {
  return numero >= 1 && numero <= 3;
}