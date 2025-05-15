async function tryLogout() {
  try {
    const res = await fetch('http://localhost:5050/auth/logout', {
      method: 'POST',
      credentials: 'include'
    });
    if (res.ok) {
      window.location.href = '/NotiSync/frontend/index.html';
    } else {
      console.warn('Erro ao fazer logout');
    }
  } catch (err) {
    console.error('Erro de rede no logout:', err);
  }
}
