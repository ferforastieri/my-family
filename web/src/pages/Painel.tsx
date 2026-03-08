const Painel = () => {
  return (
    <div className="p-8 min-h-screen bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <h1 className="text-primary font-[Pacifico] text-3xl text-center mb-8">Painel Administrativo</h1>

      <section className="bg-card dark:bg-card rounded-2xl p-8 mb-8 shadow-md">
        <h2 className="text-primary font-[Dancing_Script] text-2xl mb-4">Gerenciar Conteúdo</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mt-4">
          <div className="bg-[var(--love-bg-start)] dark:bg-card p-6 rounded-xl shadow-md hover:-translate-y-1 transition-transform cursor-pointer">
            <h3 className="text-primary font-[Dancing_Script] text-xl mb-2">Galeria de Fotos</h3>
            <p className="text-muted-foreground text-sm">Adicionar, remover ou editar fotos da galeria privada.</p>
          </div>
          <div className="bg-[var(--love-bg-start)] dark:bg-card p-6 rounded-xl shadow-md hover:-translate-y-1 transition-transform cursor-pointer">
            <h3 className="text-primary font-[Dancing_Script] text-xl mb-2">Mensagens</h3>
            <p className="text-muted-foreground text-sm">Gerenciar mensagens e declarações de amor.</p>
          </div>
          <div className="bg-[var(--love-bg-start)] dark:bg-card p-6 rounded-xl shadow-md hover:-translate-y-1 transition-transform cursor-pointer">
            <h3 className="text-primary font-[Dancing_Script] text-xl mb-2">Quiz do Amor</h3>
            <p className="text-muted-foreground text-sm">Editar perguntas e respostas do quiz.</p>
          </div>
          <div className="bg-[var(--love-bg-start)] dark:bg-card p-6 rounded-xl shadow-md hover:-translate-y-1 transition-transform cursor-pointer">
            <h3 className="text-primary font-[Dancing_Script] text-xl mb-2">Carta de Amor</h3>
            <p className="text-muted-foreground text-sm">Atualizar o conteúdo da carta de amor.</p>
          </div>
        </div>
      </section>

      <section className="bg-card dark:bg-card rounded-2xl p-8 shadow-md">
        <h2 className="text-primary font-[Dancing_Script] text-2xl mb-4">Configurações</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mt-4">
          <div className="bg-[var(--love-bg-start)] dark:bg-card p-6 rounded-xl shadow-md hover:-translate-y-1 transition-transform cursor-pointer">
            <h3 className="text-primary font-[Dancing_Script] text-xl mb-2">Alterar Senha</h3>
            <p className="text-muted-foreground text-sm">Modificar a senha de acesso ao painel.</p>
          </div>
          <div className="bg-[var(--love-bg-start)] dark:bg-card p-6 rounded-xl shadow-md hover:-translate-y-1 transition-transform cursor-pointer">
            <h3 className="text-primary font-[Dancing_Script] text-xl mb-2">Backup</h3>
            <p className="text-muted-foreground text-sm">Fazer backup dos dados e conteúdos.</p>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Painel; 