const NossaHistoria = () => {
  return (
    <div className="w-full min-h-screen p-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <h1 className="text-primary text-4xl md:text-5xl font-[Pacifico] text-center mb-8 animate-float animate-glow">
        Nossa História
      </h1>
      <div className="flex flex-col gap-8 max-w-[1000px] mx-auto">
        <section className="bg-white/90 dark:bg-card backdrop-blur-sm p-8 rounded-2xl shadow-md hover:shadow-lg hover:-translate-y-1 hover:bg-white/95 dark:hover:bg-card/95 transition-all duration-300">
          <h2 className="text-primary text-2xl font-[Dancing_Script] mb-4">
            Como Nos Conhecemos
          </h2>
          <p className="text-muted-foreground leading-relaxed text-lg">
            Nossa história começou de uma forma moderna e especial, através de um
            aplicativo de relacionamento da nossa igreja. O que começou como uma
            simples conversa logo se transformou em algo muito especial.
          </p>
        </section>

        <section className="bg-white/90 dark:bg-card backdrop-blur-sm p-8 rounded-2xl shadow-md hover:shadow-lg hover:-translate-y-1 hover:bg-white/95 dark:hover:bg-card/95 transition-all duration-300">
          <h2 className="text-primary text-2xl font-[Dancing_Script] mb-4">
            Nosso Relacionamento
          </h2>
          <p className="text-muted-foreground leading-relaxed text-lg">
            Oficialmente começamos nosso namoro em 12 de outubro de 2024.
            Desde então, temos compartilhado momentos incríveis juntos,
            construindo uma relação baseada em amor, respeito e valores em comum.
          </p>
        </section>

        <section className="bg-white/90 dark:bg-card backdrop-blur-sm p-8 rounded-2xl shadow-md hover:shadow-lg hover:-translate-y-1 hover:bg-white/95 dark:hover:bg-card/95 transition-all duration-300">
          <h2 className="text-primary text-2xl font-[Dancing_Script] mb-4">
            Nossa Conexão
          </h2>
          <p className="text-muted-foreground leading-relaxed text-lg">
            Nossa fé e valores compartilhados têm sido a base do nosso relacionamento.
            Unidos pela igreja e por nossos princípios, construímos uma conexão
            verdadeira e especial.
          </p>
        </section>
      </div>
    </div>
  );
};

export default NossaHistoria;
