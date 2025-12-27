# IAM Pages

## Registration Page

**Route:** `/auth/register`

**Поля:**
- Email
- Password
- First Name
- Last Name
- Checkbox: Создать организацию
  - → Organization Name (если checked)
- Accept Terms checkbox

**Действия:**
- Submit → POST `/api/iam/registration/personal` или `/with-organization`
- Success → redirect to `/auth/verify-email`

---

## Profile Page

**Route:** `/profile`

**Секции:**
- Avatar (upload)
- Personal info (read-only from Keycloak)
- Change password (link to Keycloak)

---

## Sessions Page

**Route:** `/profile/sessions`

**Данные:**
- List of active sessions
- Current session highlighted
- IP, User Agent, Last Activity

**Действия:**
- Revoke session button

---

## Admin: Users Page

**Route:** `/admin/users`

**Данные:**
- Table: Name, Email, Role, Status
- Pagination

**Действия:**
- Invite button → modal
- Change role dropdown
- Suspend/Activate

---

## Admin: Invite Modal

**Поля:**
- Email
- Role (select)

**Действия:**
- Send → POST `/api/iam/invites`

---

## Компоненты

Определяются после утверждения дизайна.

См. `06-Design/` (TODO)
