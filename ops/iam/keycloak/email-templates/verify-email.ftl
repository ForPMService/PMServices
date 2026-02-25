<#-- verify-email.ftl -->
<#-- Шаблон подтверждения email (KC-CONFIG-TEMPLATES) -->
<#-- Переменная ${link} автоматически использует Frontend URL из realm settings -->
<#-- Frontend URL должен быть = публичный домен Edge (KC-PRINCIPLE-001) -->
<!DOCTYPE html>
<html lang="${locale!'ru'}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${msg("emailVerificationSubject")}</title>
  <style>
    body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }
    .container { max-width: 560px; margin: 40px auto; background: #fff; border-radius: 8px; padding: 40px; }
    .btn { display: inline-block; padding: 12px 28px; background: #2563eb; color: #fff; text-decoration: none; border-radius: 6px; font-weight: bold; }
    .footer { margin-top: 32px; font-size: 12px; color: #888; }
  </style>
</head>
<body>
  <div class="container">
    <h2>Подтверждение адреса электронной почты</h2>
    <p>Здравствуйте<#if user.firstName??>, ${user.firstName}</#if>!</p>
    <p>Для завершения регистрации подтвердите ваш email-адрес, нажав кнопку ниже:</p>
    <p><a href="${link}" class="btn">Подтвердить email</a></p>
    <p>Или перейдите по ссылке:<br><a href="${link}">${link}</a></p>
    <p>Ссылка действительна <strong>${linkExpirationFormatter(linkExpiration)}</strong>.</p>
    <p>Если вы не регистрировались на нашей платформе — просто проигнорируйте это письмо.</p>
    <div class="footer">
      <p>Это письмо сгенерировано автоматически, отвечать на него не нужно.</p>
    </div>
  </div>
</body>
</html>
