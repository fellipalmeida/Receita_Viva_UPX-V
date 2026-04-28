# Receita Viva 🍳

O **Receita Viva** é um assistente culinário inteligente desenvolvido em Flutter que utiliza Inteligência Artificial para transformar a experiência na cozinha. O projeto foi concebido para o projeto **UPX-V**, focando em acessibilidade, personalização e inovação tecnológica através da integração com o Google Gemini.

## 🚀 Funcionalidades Principais

- **Chef IA (Gemini):** Chat interativo para tirar dúvidas culinárias e receber dicas em tempo real.
- **Gerador de Receitas Inteligente:** Criação de pratos completos a partir de ingredientes disponíveis ou temas específicos.
- **Filtros de Restrição:** Geração de receitas que respeitam obrigatoriamente alergias e dietas específicas (ex: Vegana, Low Carb).
- **Comunidade e Favoritos:** Espaço para explorar novas ideias e salvar suas receitas preferidas.
- **Experiência Personalizada:** Suporte a modo claro/escuro e interface intuitiva baseada no Google Fonts (Poppins).

## 📂 Estrutura do Código no GitHub

O código fonte está organizado de forma modular dentro da pasta `lib/` para facilitar a manutenção e escalabilidade:

```text
lib/
├── dados/          # Dados estáticos e mocks para desenvolvimento e testes.
├── modelos/        # Modelos de dados (Data Classes) como Receita e Perfil de Usuário.
├── servicos/       # Lógica de integração externa (Gemini API, Storage local, API de Imagens).
├── telas/          # Componentes de tela inteira (UI) organizados por funcionalidade.
├── tema/           # Configurações globais de estilo, cores e temas (Light/Dark).
├── widgets/        # Componentes de interface reutilizáveis em múltiplas telas.
└── main.dart       # Ponto de entrada do app e gerenciamento de estado global.
```

## 🛠️ Tecnologias Utilizadas

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **IA:** [Google Generative AI](https://ai.google.dev/) (Gemini API)
- **Persistência:** SharedPreferences para salvar preferências do usuário.
- **Estilização:** Google Fonts e Custom Themes para suporte a Dark Mode.

## ⚙️ Como Executar o Projeto

1. Tenha o ambiente Flutter configurado em sua máquina.
2. Clone este repositório.
3. Na raiz do projeto, execute:
   ```bash
   flutter pub get
   ```
4. **Configuração da API:** O projeto requer uma chave do Gemini. Certifique-se de que o arquivo `lib/config.dart` (ou similar conforme `config.example.dart`) contenha sua `geminiApiKey`.
5. Inicie o aplicativo:
   ```bash
   flutter run
   ```

---
*Este projeto faz parte da avaliação da disciplina de UPX-V. Todos os commits seguem as diretrizes de versionamento contínuo estabelecidas.*
