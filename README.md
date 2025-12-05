# Configuração Neovim

Uma configuração personalizada e completa do Neovim, otimizada para desenvolvimento com suporte a LSP, DAP, formatação automática, e muito mais.

## Características

- **Gerenciador de Plugins**: Lazy.nvim para carregamento eficiente
- **Realce de Sintaxe**: Treesitter com suporte a múltiplas linguagens
- **Completamento**: Blink.cmp com integração LSP, snippets e Codeium (Windsurf)
- **Formatação**: Conform.nvim para formatação automática
- **Git**: Gitsigns, Neogit e Diffview para integração Git
- **Java**: Suporte completo com JDTLS, Spring Boot e Quarkus
- **Debugging**: DAP com suporte a Python e Java
- **Banco de Dados**: Dadbod para consultas SQL
- **Notas**: Zk para gerenciamento de notas Markdown
- **Interface**: Snacks.nvim para melhorias na UI
- **Neovide**: Configuração otimizada para GUI

## Requisitos

- Neovim 0.9+
- Git
- Ripgrep (rg) para busca
- Fontes Nerd Font (recomendado: CaskaydiaMono Nerd Font)

### Dependências de Linguagem

- **Lua**: StyLua
- **Python**: Black
- **JavaScript/CSS/HTML**: Prettier
- **SQL**: SQL Formatter
- **Bash**: Shfmt
- **TOML**: Taplo

## Instalação

1. Clone este repositório para o diretório de configuração do Neovim:

```bash
git clone https://github.com/seu-usuario/sua-config-neovim ~/.config/nvim
```

2. Inicie o Neovim. O Lazy.nvim será instalado automaticamente junto com todos os plugins.

```bash
nvim
```

3. Instale as dependências externas necessárias (opcional, mas recomendado):

```bash
# Para Java
brew install openjdk
# Para Python
pip install black
# Para Node.js (para Prettier, etc.)
npm install -g prettier
# Para Lua
cargo install stylua
```

## Estrutura dos Arquivos

```
~/.config/nvim/
├── init.lua          # Arquivo principal de configuração
├── lua/
│   ├── plugins.lua   # Definições dos plugins
│   ├── options.lua   # Opções do Neovim
│   ├── mappings.lua  # Mapeamentos de teclas
│   ├── autocmds.lua  # Comandos automáticos
│   ├── global.lua    # Configurações globais
│   ├── experimental.lua # Recursos experimentais
│   └── kide/         # Módulo personalizado
│       ├── lsp/      # Configurações LSP
│       ├── tools/    # Ferramentas utilitárias
│       ├── gpt/      # Integração GPT
│       └── ...
├── after/            # Configurações pós-carregamento
├── ftplugin/         # Configurações por tipo de arquivo
├── syntax/           # Definições de sintaxe
└── colors/           # Esquemas de cores
```

## Configurações Principais

### Tema
- **Cores**: Gruvbox (escuro)
- **Fonte GUI**: CaskaydiaMono Nerd Font (configurável via `NVIM_GUI_FONT`)

### LSP e Completamento
- Servidores LSP configurados via módulo `kide.lsp`
- Completamento com Blink.cmp
- Snippets via Friendly Snippets
- Integração com Codeium (via Windsurf)

### Formatação
Formatters configurados por tipo de arquivo:
- Lua: StyLua
- Python: Black
- JavaScript/HTML/CSS: Prettier
- SQL: SQL Formatter

### Debugging
- Suporte DAP para Python e Java
- Virtual text para breakpoints
- Interface de debug integrada

## Comandos Úteis

- `:Lazy` - Gerenciar plugins
- `:Mason` - Instalar servidores LSP
- `:ConformInfo` - Verificar formatters
- `:Neogit` - Interface Git
- `:DBUI` - Interface de banco de dados
- `:ZkNotes` - Gerenciar notas
- `:Outline` - Mostrar estrutura do arquivo

## Personalização

### Adicionar Plugins
Edite `lua/plugins.lua` para adicionar novos plugins:

```lua
{
  "autor/plugin",
  config = function()
    -- configuração aqui
  end,
}
```

### Mapeamentos de Tecla
Modifique `lua/mappings.lua` para adicionar atalhos personalizados.

### Opções
Ajuste configurações em `lua/options.lua`.

## Licença

Este projeto está licenciado sob as licenças Apache 2.0 e GPL. Verifique os arquivos LICENSE-APACHE e LICENSE-GPL para mais detalhes.
