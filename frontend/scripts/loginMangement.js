function togglePassword() {
    let inputComponent = document.querySelector("#password");
    let toggleComponent = document.querySelector(".togglePassword");


    if (inputComponent.type === "password") {
        inputComponent.type = "text";
        toggleComponent.innerHTML = "<i class='fa-solid fa-eye-slash'></i>";
    } else {
        inputComponent.type = "password";
        toggleComponent.innerHTML = "<i class='fa-solid fa-eye'></i>";
    }
}

function triggerError(type) {
  // Se não vier type ou for vazio, aborta
  if (!type) return;

  const errorComponent = document.querySelector(".error");
  if (!errorComponent) {
    console.warn("Elemento .error não encontrado no DOM.");
    return;
  }

  // Mensagem por tipo de erro
  let msg;
  switch (type) {
    case "wrongInput":
      msg = "Email ou Palavra-passe incorretos. Tente novamente!";
      break;
    case "invalidInput":
      msg = "Preencha todos os campos e tente novamente.";
      break;
    default:
      msg = "Ocorreu um erro desconhecido.";
  }

  // Mostra o erro
  errorComponent.textContent = msg;
  errorComponent.classList.add("triggered");

  // Passado 3s, limpa tudo
  setTimeout(() => {
    errorComponent.textContent = "";
    errorComponent.classList.remove("triggered");
  }, 3000);
}

async function tryLogin(e) {
  // Evita que o form faça submit nativo
  e.preventDefault();

  // Lê valores do form
  const email    = document.getElementById('email').value.trim();
  const password = document.getElementById('password').value;

  try {
    // Envia pedido ao backend Flask
    const res = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',             // importante para cookies HttpOnly
      body: JSON.stringify({ email, password })
    });

    const data = await res.json();
    console.log('login response', res.status, data);

    if (res.ok) {
      // Login bem-sucedido — cookie jwt_token já foi definido pelo servidor
      console.log('Login efetuado:', data.message);
      // Redireciona para o dashboard
      window.location.href = '/NotiSync/frontend/pages/dashboard.html';
    } else {
      // Tratar erros específicos devolvidos pelo Flask
      console.warn('Erro no login:', data.message, data.error);
      triggerError(data.error || 'Erro no login');
    }
  } catch (err) {
    console.error('Erro de rede:', err);
    triggerError('networkError');
  }
}
