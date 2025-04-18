import os

nombre_archivo = "estructura_lib.txt"

def listar_estructura(ruta_base, archivo_actual):
    excluir = {nombre_archivo, os.path.basename(archivo_actual), "DartGenerator.py", "pepe.dart"}

    with open(nombre_archivo, "w", encoding="utf-8") as f:
        f.write("Estructura del proyecto\n")
        for root, dirs, files in os.walk(ruta_base):
            nivel = root.replace(ruta_base, '').count(os.sep)
            indent = '│   ' * nivel + ('├── ' if nivel > 0 else '')
            carpeta = os.path.basename(root)
            if carpeta != ".":
                f.write(f"{indent}{carpeta}/\n")
            subindent = '│   ' * (nivel + 1)
            for file in sorted(files):
                if file not in excluir:
                    f.write(f"{subindent}└── {file}\n")
    print(f"Estructura guardada en: {nombre_archivo}")

# Ejecutar desde la carpeta lib
if __name__ == "__main__":
    archivo_actual = __file__
    ruta_lib = os.path.dirname(os.path.abspath(archivo_actual))
    listar_estructura(ruta_lib, archivo_actual)
