<#-- execute-actions.ftl -->
<#-- Шаблон для action-token писем: reset password, execute actions (KC-CONFIG-TEMPLATES) -->
<#-- Переменная ${link} использует Frontend URL из realm settings = публичный Edge-домен -->
<!DOCTYPE html>
<html lang="${locale!'ru'}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${msg("executeActionsSubject")}</title>
  <style>
    body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }
    .container { max-width: 560px; margin: 40px auto; background: #fff; border-radius: 8px; padding: 40px; }
    .btn { display: inline-block; padding: 12px 28px; background: #2563eb; color: #fff; text-decoration: none; border-radius: 6px; font-weight: bold; }
    .footer { margin-top: 32px; font-size: 12px; color: #888; }
    .warning { background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px 16px; border-radius: 4px; margin: 16px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h2>Действие с вашей учётной записью</h2>
    <p>Здравствуйте<#if user.firstName??>, ${user.firstName}</#if>!</p>

    <#-- Список запрошенных действий (сброс пароля, верификация и т.д.) -->
    <#if requiredActions??>
      <p>Для вашей учётной записи запрошены следующие действия:</p>
      <ul>
        <#list requiredActions as action>
          <li>${msg("requiredAction.${action}")}</li>
        </#list>
      </ul>
    </#if>

    <p>Нажмите кнопку ниже, чтобы выполнить запрошенные действия:</p>
    <p><a href="${link}" class="btn">Выполнить действие</a></p>
    <p>Или перейдите по ссылке:<br><a href="${link}">${link}</a></p>
    <p>Ссылка действительна <strong>${linkExpirationFormatter(linkExpiration)}</strong>.</p>

    <div class="warning">
      <strong>Важно:</strong> Если вы не запрашивали это действие — немедленно свяжитесь с поддержкой и смените пароль.
    </div>

    <div class="footer">
      <p>Это письмо сгенерировано автоматически, отвечать на него не нужно.</p>
    </div>
  </div>
</body>
</html>
