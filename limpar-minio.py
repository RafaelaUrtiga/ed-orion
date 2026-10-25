# Remove do bucket tudo o que nao for PDF (limpeza dos testes da etapa inicial).
import os

from minio import Minio

client = Minio(
    os.environ.get("MINIO_HOST", "localhost:9000"),
    access_key=os.environ["MINIO_KEY"],
    secret_key=os.environ["MINIO_SECRET"],
    secure=False,
)
bucket = os.environ.get("MINIO_BUCKET", "dados-brutos")

removidos = 0
for obj in client.list_objects(bucket, recursive=True):
    nome = obj.object_name
    if not nome.lower().endswith(".pdf"):
        client.remove_object(bucket, nome)
        print(f"Removido: {nome}")
        removidos += 1

print(f"\nTotal removido: {removidos}")
print("Sobraram apenas os PDFs.")
