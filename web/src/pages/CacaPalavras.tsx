import { useState, useEffect } from 'react';

const PALAVRAS_POSSIVEIS = [
  'AMOR', 'BEIJO', 'CARINHO', 'ABRACO', 'PAIXAO',
  'ROMANCE', 'TERNURA', 'AFETO', 'CORACAO', 'SAUDADE',
  'NAMORO', 'FAMILIA', 'ALEGRIA', 'FELIZ', 'SONHOS'
];

const CacaPalavras = () => {
  const [grid, setGrid] = useState<string[][]>([]);
  const [palavrasDoDia, setPalavrasDoDia] = useState<string[]>([]);
  const [palavrasEncontradas, setPalavrasEncontradas] = useState<string[]>([]);
  const [selectedCells, setSelectedCells] = useState<number[]>([]);
  const [showParabens, setShowParabens] = useState(false);

  const gerarPalavrasDoDia = () => {
    const hoje = new Date().toISOString().split('T')[0];
    const seed = hoje.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
    const palavrasEmbaralhadas = [...PALAVRAS_POSSIVEIS].sort(() => {
      return 0.5 - Math.random() + Math.sin(seed);
    });
    return palavrasEmbaralhadas.slice(0, 6);
  };

  const criarGrid = (palavras: string[]): string[][] => {
    const grid: string[][] = Array(15).fill(null).map(() =>
      Array(15).fill(null).map(() =>
        String.fromCharCode(65 + Math.floor(Math.random() * 26))
      )
    );

    const tentarInserirPalavra = (palavra: string): boolean => {
      const maxTentativas = 100;
      let tentativas = 0;
      while (tentativas < maxTentativas) {
        const direcao = Math.random() < 0.5 ? 'horizontal' : 'vertical';
        const maxRow = direcao === 'horizontal' ? 15 : 15 - palavra.length;
        const maxCol = direcao === 'horizontal' ? 15 - palavra.length : 15;
        const row = Math.floor(Math.random() * maxRow);
        const col = Math.floor(Math.random() * maxCol);
        let podeInserir = true;
        for (let i = 0; i < palavra.length; i++) {
          const currentRow = direcao === 'horizontal' ? row : row + i;
          const currentCol = direcao === 'horizontal' ? col + i : col;
          const letraAtual = grid[currentRow][currentCol];
          if (letraAtual !== palavra[i] && letraAtual !== '') {
            podeInserir = false;
            break;
          }
        }
        if (podeInserir) {
          for (let i = 0; i < palavra.length; i++) {
            const currentRow = direcao === 'horizontal' ? row : row + i;
            const currentCol = direcao === 'horizontal' ? col + i : col;
            grid[currentRow][currentCol] = palavra[i];
          }
          return true;
        }
        tentativas++;
      }
      return false;
    };

    for (let i = 0; i < 15; i++) {
      for (let j = 0; j < 15; j++) {
        grid[i][j] = '';
      }
    }
    palavras.forEach(palavra => tentarInserirPalavra(palavra));
    for (let i = 0; i < 15; i++) {
      for (let j = 0; j < 15; j++) {
        if (grid[i][j] === '') {
          grid[i][j] = String.fromCharCode(65 + Math.floor(Math.random() * 26));
        }
      }
    }
    return grid;
  };

  useEffect(() => {
    const palavras = gerarPalavrasDoDia();
    setPalavrasDoDia(palavras);
    setGrid(criarGrid(palavras));
  }, []);

  const reiniciarJogo = () => {
    const novasPalavras = gerarPalavrasDoDia();
    setPalavrasDoDia(novasPalavras);
    setGrid(criarGrid(novasPalavras));
    setPalavrasEncontradas([]);
    setSelectedCells([]);
    setShowParabens(false);
  };

  const handleCellClick = (index: number) => {
    if (selectedCells.includes(index)) {
      setSelectedCells(selectedCells.filter(i => i !== index));
    } else {
      const novaSelecao = [...selectedCells, index];
      setSelectedCells(novaSelecao);
      const palavra = novaSelecao.map(idx => {
        const row = Math.floor(idx / 15);
        const col = idx % 15;
        return grid[row][col];
      }).join('');
      if (palavrasDoDia.includes(palavra) && !palavrasEncontradas.includes(palavra)) {
        const novasEncontradas = [...palavrasEncontradas, palavra];
        setPalavrasEncontradas(novasEncontradas);
        setSelectedCells([]);
        if (novasEncontradas.length === palavrasDoDia.length) {
          setShowParabens(true);
        }
      }
    }
  };

  return (
    <div className="w-full min-h-screen bg-gradient-to-b from-[var(--love-bg-start)] to-[var(--love-bg-end)] p-8">
      <h1 className="text-primary text-3xl font-[Pacifico] text-center mb-8">Caça Palavras do Amor</h1>
      <div className="flex flex-wrap justify-center gap-4 my-8 max-w-[600px] mx-auto">
        {palavrasDoDia.map(palavra => (
          <div
            key={palavra}
            className={`px-4 py-2 rounded-full shadow-md ${
              palavrasEncontradas.includes(palavra)
                ? 'bg-primary text-primary-foreground'
                : 'bg-card text-muted-foreground'
            }`}
          >
            {palavra}
          </div>
        ))}
      </div>
      <div className="grid gap-0.5 justify-center mx-auto my-8 bg-card p-4 rounded-xl shadow-md w-fit" style={{ gridTemplateColumns: 'repeat(15, 30px)' }}>
        {grid.flat().map((letra, index) => (
          <div
            key={index}
            role="button"
            tabIndex={0}
            onClick={() => handleCellClick(index)}
            onKeyDown={(e) => e.key === 'Enter' && handleCellClick(index)}
            className={`w-[30px] h-[30px] flex items-center justify-center border cursor-pointer select-none transition-colors text-sm ${
              selectedCells.includes(index)
                ? 'bg-primary text-primary-foreground border-primary'
                : 'bg-background text-muted-foreground border-input hover:bg-accent'
            }`}
          >
            {letra}
          </div>
        ))}
      </div>

      {showParabens && (
        <div className="fixed inset-0 bg-primary/90 flex flex-col items-center justify-center z-[1000] animate-fade-in">
          <h2 className="text-white text-3xl font-[Pacifico] text-center mb-8 drop-shadow">
            Parabéns! 🎉<br />
            Você encontrou todas as palavras!
          </h2>
          <button
            type="button"
            onClick={reiniciarJogo}
            className="bg-card text-primary border-0 py-4 px-8 rounded-[25px] text-xl cursor-pointer transition-transform hover:scale-105 shadow-lg"
          >
            Jogar Novamente
          </button>
        </div>
      )}
    </div>
  );
};

export default CacaPalavras;
