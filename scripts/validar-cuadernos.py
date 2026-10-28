"""Ejecuta los cuadernos sin editar los originales; crea datos con un alumno único."""
import argparse
from pathlib import Path
import shutil
import tempfile
from uuid import uuid4
import nbformat
from nbclient import NotebookClient

parser = argparse.ArgumentParser()
parser.add_argument('--source', default='/media/notebooks/lake')
args = parser.parse_args()
carpeta = Path(tempfile.mkdtemp(prefix='bda-cuadernos-'))
shutil.copytree(args.source, carpeta / 'lake', ignore=shutil.ignore_patterns('datos', '__pycache__', '.ipynb_checkpoints'))
carpeta = carpeta / 'lake'
alumno = 'validacion_' + uuid4().hex[:8]
(carpeta / 'configuracion.py').write_text(f'ALUMNO = "{alumno}"\n')
print(f'Alumno de prueba: {alumno}', flush=True)
for archivo in sorted(carpeta.glob('*.ipynb')):
    cuaderno = nbformat.read(archivo, as_version=4)
    NotebookClient(cuaderno, timeout=900, kernel_name='python3',
                   resources={'metadata': {'path': str(carpeta)}}).execute()
    nbformat.write(cuaderno, archivo)
    print(f'OK {archivo.name}', flush=True)
print(f'Cuadernos ejecutados: {carpeta}', flush=True)
print('Se conservan los datos de prueba bajo su identificador; no se borran tablas ni archivos de alumnos.', flush=True)
