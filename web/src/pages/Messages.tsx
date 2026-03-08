const Messages = () => {
  const messages = [
    {
      id: 1,
      title: "Meu Amor",
      content: "Cada dia ao seu lado é uma nova aventura cheia de amor e felicidade...",
      date: "10 de Novembro, 2024"
    },
    {
      id: 2,
      title: "Para Sempre",
      content: "Você é o sonho que eu não sabia que tinha até te encontrar...",
      date: "11 de Fevereiro, 2024"
    },
  ];

  return (
    <div className="min-h-screen pt-20 px-6 pb-8 bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)]">
      <h1 className="text-primary text-3xl md:text-4xl font-[Dancing_Script] text-center mb-8">
        Mensagens do Coração
      </h1>
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8 max-w-[1200px] mx-auto">
        {messages.map((message) => (
          <div
            key={message.id}
            className="bg-card/90 dark:bg-card p-8 rounded-2xl shadow-md hover:-translate-y-1 transition-all duration-300"
          >
            <h3 className="text-primary text-xl font-[Pacifico] mb-4">{message.title}</h3>
            <p className="text-muted-foreground leading-relaxed text-lg">{message.content}</p>
            <p className="text-primary text-sm mt-4 text-right italic">{message.date}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Messages;
