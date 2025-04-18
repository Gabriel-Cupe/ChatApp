import os

estructura = {
    "lib": {
        "screens": ["chat_screen.dart"],
        "chat_addons": [
            "chat_bubble.dart",
            "reply_bubble.dart",
            "reply_panel.dart",
            "message_input.dart",
            "chat_functions.dart"
        ]
    }
}

def crear_estructura(base_path, estructura):
    for carpeta, contenido in estructura.items():
        for subcarpeta, archivos in contenido.items():
            ruta = os.path.join(base_path, carpeta, subcarpeta)
            os.makedirs(ruta, exist_ok=True)
            for archivo in archivos:
                archivo_path = os.path.join(ruta, archivo)
                if not os.path.exists(archivo_path):
                    with open(archivo_path, 'w') as f:
                        f.write(f"// Archivo: {archivo}\n")
                    print(f"Creado: {archivo_path}")
                else:
                    print(f"Omitido (ya existe): {archivo_path}")

crear_estructura(".", estructura)
