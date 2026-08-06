# Assinatura e releases Android

O keystore privado nunca deve ser enviado ao Git. O workflow usa quatro
Repository Secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

O valor de `ANDROID_KEYSTORE_BASE64` é o conteúdo integral do keystore
codificado em base64, sem quebras de linha. Os outros três valores devem ser os
mesmos usados durante a criação do keystore.

Uma publicação exige:

1. aumentar `version: nome+código` no `pubspec.yaml`;
2. aprovar análise, testes e build de validação;
3. executar o workflow manualmente com `publish_release=true` ou usar
   `[release]` na mensagem do commit autorizado;
4. criar uma release imutável no formato `v1.1.0+2` com `FinFlow.apk` e
   `FinFlow.apk.sha256`.

O workflow recusa publicar novamente uma versão existente. Isso impede que dois
APKs diferentes usem o mesmo número de versão.
