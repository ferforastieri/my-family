import styled from 'styled-components';
import { useState, useEffect } from 'react';

const Container = styled.div`
  width: 100%;
  min-height: 100vh;
  background: linear-gradient(180deg, #fff8fa 0%, #fff0f5 100%);
  padding: 2rem;
`;

const Title = styled.h1`
  color: #ff69b4;
  font-size: 2.5rem;
  font-family: 'Pacifico', cursive;
  text-align: center;
  margin-bottom: 2rem;
`;

const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(15, 30px);
  gap: 2px;
  justify-content: center;
  margin: 2rem auto;
  background: white;
  padding: 1rem;
  border-radius: 10px;
  box-shadow: 0 4px 15px rgba(255, 105, 180, 0.2);
`;

const Cell = styled.div<{ isSelected: boolean }>`
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #ffd1dc;
  cursor: pointer;
  user-select: none;
  background-color: ${props => props.isSelected ? '#ff69b4' : 'white'};
  color: ${props => props.isSelected ? 'white' : '#666'};
  transition: all 0.2s ease;

  &:hover {
    background-color: #ffd1dc;
  }
`;

const WordList = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  justify-content: center;
  margin: 2rem auto;
  max-width: 600px;
`;

const Word = styled.div<{ found: boolean }>`
  padding: 0.5rem 1rem;
  background: ${props => props.found ? '#ff69b4' : 'white'};
  color: ${props => props.found ? 'white' : '#666'};
  border-radius: 20px;
  box-shadow: 0 2px 8px rgba(255, 105, 180, 0.2);
`;

// Palavras relacionadas ao amor que podem aparecer no jogo
const PALAVRAS_POSSIVEIS = [
  'AMOR', 'BEIJO', 'CARINHO', 'ABRACO', 'PAIXAO',
  'ROMANCE', 'TERNURA', 'AFETO', 'CORACAO', 'SAUDADE',
  'NAMORO', 'FAMILIA', 'ALEGRIA', 'FELIZ', 'SONHOS'
];

const ParabensContainer = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 105, 180, 0.9);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.5s ease;

  @keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
  }
`;

const ParabensMessage = styled.h2`
  color: white;
  font-size: 2.5rem;
  font-family: 'Pacifico', cursive;
  text-align: center;
  margin-bottom: 2rem;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
`;

const NovoJogoButton = styled.button`
  background: white;
  color: #ff69b4;
  border: none;
  padding: 1rem 2rem;
  border-radius: 25px;
  font-size: 1.2rem;
  cursor: pointer;
  transition: transform 0.2s ease;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);

  &:hover {
    transform: scale(1.05);
  }
`;

const CacaPalavras = () => {
  const [grid, setGrid] = useState<string[][]>([]);
  const [palavrasDoDia, setPalavrasDoDia] = useState<string[]>([]);
  const [palavrasEncontradas, setPalavrasEncontradas] = useState<string[]>([]);
  const [selectedCells, setSelectedCells] = useState<number[]>([]);
  const [showParabens, setShowParabens] = useState(false);

  // Função para gerar palavras do dia baseado na data
  const gerarPalavrasDoDia = () => {
    const hoje = new Date().toISOString().split('T')[0];
    const seed = hoje.split('').reduce((a, b) => a + b.charCodeAt(0), 0);
    const palavrasEmbaralhadas = [...PALAVRAS_POSSIVEIS].sort(() => {
      return 0.5 - Math.random() + Math.sin(seed); // Usando seed na ordenação
    });
    return palavrasEmbaralhadas.slice(0, 6);
  };

  // Função para criar o grid com as palavras
  const criarGrid = (palavras: string[]): string[][] => {
    // Criar grid vazio 15x15 com letras aleatórias
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

        // Verificar se o espaço está livre ou tem letra compatível
        for (let i = 0; i < palavra.length; i++) {
          const currentRow = direcao === 'horizontal' ? row : row + i;
          const currentCol = direcao === 'horizontal' ? col + i : col;
          const letraAtual = grid[currentRow][currentCol];
          
          // Só pode inserir se a posição estiver vazia ou tiver a mesma letra
          if (letraAtual !== palavra[i] && letraAtual !== '') {
            podeInserir = false;
            break;
          }
        }

        if (podeInserir) {
          // Inserir a palavra
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

    // Primeiro, limpar o grid com espaços vazios
    for (let i = 0; i < 15; i++) {
      for (let j = 0; j < 15; j++) {
        grid[i][j] = '';
      }
    }

    // Inserir cada palavra
    palavras.forEach(palavra => {
      tentarInserirPalavra(palavra);
    });

    // Preencher espaços vazios com letras aleatórias
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
    const novoGrid = criarGrid(palavras);
    setGrid(novoGrid);
  }, []);

  const reiniciarJogo = () => {
    const novasPalavras = gerarPalavrasDoDia();
    setPalavrasDoDia(novasPalavras);
    const novoGrid = criarGrid(novasPalavras);
    setGrid(novoGrid);
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

        // Verificar se todas as palavras foram encontradas
        if (novasEncontradas.length === palavrasDoDia.length) {
          setShowParabens(true);
        }
      }
    }
  };

  return (
    <Container>
      <Title>Caça Palavras do Amor</Title>
      <WordList>
        {palavrasDoDia.map(palavra => (
          <Word key={palavra} found={palavrasEncontradas.includes(palavra)}>
            {palavra}
          </Word>
        ))}
      </WordList>
      <Grid>
        {grid.flat().map((letra, index) => (
          <Cell
            key={index}
            isSelected={selectedCells.includes(index)}
            onClick={() => handleCellClick(index)}
          >
            {letra}
          </Cell>
        ))}
      </Grid>

      {showParabens && (
        <ParabensContainer>
          <ParabensMessage>
            Parabéns! 🎉<br/>
            Você encontrou todas as palavras!
          </ParabensMessage>
          <NovoJogoButton onClick={reiniciarJogo}>
            Jogar Novamente
          </NovoJogoButton>
        </ParabensContainer>
      )}
    </Container>
  );
};

export default CacaPalavras; 