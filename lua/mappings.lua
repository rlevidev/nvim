-- add yours here

local map = vim.keymap.set
local command = vim.api.nvim_create_user_command

map("n", "<A-i>", function()
  require("kide.term").toggle()
  vim.cmd("startinsert")
end, { desc = "toggle term" })
map("t", "<A-i>", require("kide.term").toggle, { desc = "toggle term" })
map("i", "<A-i>", function()
  vim.cmd("stopinsert")
  require("kide.term").toggle()
end, { desc = "toggle term" })
map("v", "<A-i>", function()
  vim.api.nvim_feedkeys("\027", "xt", false)
  local text = require("kide.tools").get_visual_selection()
  require("kide.term").toggle()
  vim.defer_fn(function()
    require("kide.term").send_line(text[1])
  end, 500)
end, { desc = "toggle term" })

map("n", "<leader>gb", require("gitsigns").blame_line, { desc = "gitsigns blame line" })
map("n", "<ESC>", "<CMD>noh<CR>", { desc = "Clear Highlight" })

map("n", "<up>", "<CMD>res +5<CR>", { desc = "Resize +5" })
map("n", "<down>", "<CMD>res -5<CR>", { desc = "Resize -5" })
map("n", "<S-up>", "<CMD>res -5<CR>", { desc = "Resize -5" })
map("n", "<S-down>", "<CMD>res +5<CR>", { desc = "Resize +5" })
map("n", "<left>", "<CMD>vertical resize+5<CR>", { desc = "Vertical Resize +5" })
map("n", "<right>", "<CMD>vertical resize-5<CR>", { desc = "Vertical Resize -5" })
map("n", "<S-left>", "<CMD>vertical resize-5<CR>", { desc = "Vertical Resize -5" })
map("n", "<S-right>", "<CMD>vertical resize+5<CR>", { desc = "Vertical Resize +5" })

vim.keymap.set({ "t", "i" }, "<A-h>", "<C-\\><C-n><C-w>h")
vim.keymap.set({ "t", "i" }, "<A-j>", "<C-\\><C-n><C-w>j")
vim.keymap.set({ "t", "i" }, "<A-k>", "<C-\\><C-n><C-w>k")
vim.keymap.set({ "t", "i" }, "<A-l>", "<C-\\><C-n><C-w>l")
vim.keymap.set({ "n" }, "<A-h>", "<C-w>h")
vim.keymap.set({ "n" }, "<A-j>", "<C-w>j")
vim.keymap.set({ "n" }, "<A-k>", "<C-w>k")
vim.keymap.set({ "n" }, "<A-l>", "<C-w>l")
-- terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- dap
map("n", "<F5>", function()
  require("dap").continue()
end, {
  desc = "Dap continue",
})
map("n", "<F10>", function()
  require("dap").step_over()
end, {
  desc = "Dap step_over",
})
map("n", "<F11>", function()
  require("dap").step_into()
end, {
  desc = "Dap step_into",
})
map("n", "<F12>", function()
  require("dap").step_out()
end, {
  desc = "Dap step_out",
})
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Dap toggle breakpoint" })
map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Dap breakpoint condition" })
map("n", "<leader>dl", function()
  require("dap").run_last()
end, {
  desc = "Dap run last",
})
map("n", "<Leader>lp", function()
  require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, {
  desc = "Dap set_breakpoint",
})
map("n", "<Leader>dr", function()
  require("dap").repl.open()
end, {
  desc = "Dap repl open",
})
map({ "n", "v" }, "<Leader>dh", function()
  require("dap.ui.widgets").hover()
end, {
  desc = "Dap hover",
})
map({ "n", "v" }, "<Leader>dp", function()
  require("dap.ui.widgets").preview()
end, {
  desc = "Dap preview",
})
map("n", "<Leader>df", function()
  local widgets = require("dap.ui.widgets")
  widgets.centered_float(widgets.frames)
end, {
  desc = "Dap centered_float frames",
})
map("n", "<Leader>dv", function()
  local widgets = require("dap.ui.widgets")
  widgets.centered_float(widgets.scopes)
end, {
  desc = "Dap centered_float scopes",
})

-- Templates Java básicos para criação rápida de arquivos
local java_templates = {
  ["class"] = [[package com.example;

public class %s {
    -- TODO: implementar
}]],
  ["record"] = [[package com.example;

public record %s(
    -- Campos do record
) {
    -- Construtores e métodos adicionais se necessário
}]],
  ["interface"] = [[package com.example;

public interface %s {
    -- TODO: definir métodos
}]],
  ["enum"] = [[package com.example;

public enum %s {
    -- Valores do enum
}]],
}

-- ====== Início: funções para detectar package pelo pom.xml e project root ======

-- Encontra o diretório raiz do projeto subindo até encontrar pom.xml ou até chegar em /
local function find_project_root(startpath)
  startpath = startpath or vim.fn.getcwd()
  local path = vim.fn.fnamemodify(startpath, ":p")
  while path and path ~= "/" do
    if vim.fn.filereadable(path .. "pom.xml") == 1 then
      return vim.fn.fnamemodify(path, ":p")
    end
    -- volta um nível
    local parent = vim.fn.fnamemodify(path, ":h")
    if parent == path then break end
    path = parent
  end
  return nil
end

-- Lê arquivo inteiro em string (retorna nil se não existir)
local function read_file_to_string(filepath)
  if vim.fn.filereadable(filepath) == 0 then return nil end
  local f = io.open(filepath, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

-- Parse atualizado que retorna groupId e artifactId (dando prioridade ao groupId do próprio <project>)
local function parse_pom_for_group_and_artifact(pom_path)
  local content = read_file_to_string(pom_path)
  if not content then return nil, nil end

  -- normalize (remove quebras e tabs)
  local s = content:gsub("[\r\n\t]", " ")

  -- utilitária: extrai primeira ocorrência entre tags (não-gulosa)
  local function extract_tag(str, tag)
    local pat = "<%s*"..tag.."%s*>%s*(.-)%s*</%s*"..tag.."%s*>"
    local m = str:match(pat)
    if m then
      return m:match("^%s*(.-)%s*$") -- trim
    end
    return nil
  end

  -- captura bloco <project>...</project>
  local project_block = s:match("<%s*project.->(.-)</%s*project%s*>")
  if project_block then
    -- remove o bloco <parent>...</parent> temporariamente para procurar valores do próprio project
    local project_without_parent = project_block:gsub("<%s*parent.->(.-)</%s*parent%s*>", " ")

    -- tenta groupId no próprio project
    local group = extract_tag(project_without_parent, "groupId")
    -- tenta artifactId no próprio project
    local artifact = extract_tag(project_without_parent, "artifactId")

    -- se não encontrou group no próprio project, tenta parent
    if (not group or group == "") then
      local parent_block = project_block:match("<%s*parent.->(.-)</%s*parent%s*>")
      if parent_block then
        group = extract_tag(parent_block, "groupId")
      end
    end

    -- se artifact estiver vazio no project, tenta pegar qualquer artifact global (fallback)
    if (not artifact or artifact == "") then
      artifact = extract_tag(s, "artifactId")
    end

    return group, artifact
  end

  -- fallback global (caso não haja um bloco project detectado)
  local group = extract_tag(s, "groupId")
  local artifact = extract_tag(s, "artifactId")
  return group, artifact
end

-- Detecta package a partir do pom (concatena groupId + artifactId quando apropriado)
local function detect_package_from_pom(startpath)
  local root = find_project_root(startpath)
  if not root then
    return "com.example", nil
  end

  local pom = root .. "pom.xml"
  local group, artifact = parse_pom_for_group_and_artifact(pom)

  -- Normaliza strings
  if group then group = group:match("^%s*(.-)%s*$") end
  if artifact then artifact = artifact:match("^%s*(.-)%s*$") end

  -- Se tivermos groupId, tentamos usar groupId[.artifactId] (se fizer sentido)
  if group and group ~= "" then
    -- se artifact existir e não estiver "dentro" do group e não for vazio, concatenamos
    if artifact and artifact ~= "" then
      -- evita duplicar se artifact já é sufixo do group (ex: group=com.example.app artifact=app)
      if not group:match("%." .. artifact .. "$") and group ~= artifact then
        local pkg = group .. "." .. artifact
        -- substituir caracteres inválidos (apenas segurança mínima)
        pkg = pkg:gsub("[^%w%.]", "_")
        return pkg, root
      end
    end
    -- caso contrário, usa só group
    local pkg = group:gsub("[^%w%.]", "_")
    return pkg, root
  end

  -- se não houver groupId, mas houver artifactId, usa artifact como package (menos ideal)
  if artifact and artifact ~= "" then
    local pkg = artifact:gsub("[^%w%.]", "_")
    return pkg, root
  end

  -- fallback final
  return "com.example", root
end


-- ====== Fim: funções para detectar package pelo pom.xml e project root ======

-- Função para converter package em caminho de diretório
local function package_to_path(package_name)
  if not package_name or package_name == "" or package_name == "com.example" then
    return ""
  end
  return package_name:gsub("%.", "/")
end

-- Função para mover arquivo para o local correto baseado no package
-- agora usa o project_root detectado (se fornecido) ou cwd
local function move_file_to_package_location(filename, package_name, project_root)
  if not project_root or project_root == "" then
    project_root = vim.fn.getcwd()
  end

  if not package_name or package_name == "" or package_name == "com.example" then
    return filename -- Não mover se for o package padrão
  end

  local package_path = package_to_path(package_name)
  local target_dir = project_root .. "/src/main/java/" .. package_path

  -- Cria o diretório se não existir (modo recursivo)
  vim.fn.mkdir(target_dir, "p")

  -- Novo caminho do arquivo
  local class_name = vim.fn.fnamemodify(filename, ":t")
  local new_filename = target_dir .. "/" .. class_name

  -- Se já estiver no destino, não mover
  if vim.fn.fnamemodify(filename, ":p") == vim.fn.fnamemodify(new_filename, ":p") then
    return filename
  end

  local ok, err = pcall(function()
    vim.fn.rename(filename, new_filename)
  end)
  if ok then
    -- Reabre o arquivo no novo local
    vim.cmd("edit " .. vim.fn.fnameescape(new_filename))
    vim.notify("📁 Arquivo movido para: " .. new_filename, vim.log.levels.INFO)
    return new_filename
  else
    vim.notify("❌ Erro ao mover arquivo: " .. tostring(err), vim.log.levels.ERROR)
    return filename
  end
end

-- Função para criar arquivo Java com template (usa detecção automática do package pelo pom.xml)
local function create_java_file_with_template(template_type)
  return function()
    -- detecta project root e package inicialmente
    local cwd = vim.fn.getcwd()
    local detected_package, project_root = detect_package_from_pom(cwd)
    local initial_package = detected_package or "com.example"
    project_root = project_root or cwd

    -- Pega o nome da classe do usuário
    vim.ui.input({
      prompt = string.format("Nome da %s: ", template_type),
      default = "NomeClasse"
    }, function(class_name)
      if not class_name or class_name == "" then return end

      -- Segundo input: package (preenchido automaticamente com o valor detectado)
      vim.ui.input({
        prompt = "Package (ex: com.minhaempresa.projeto.model): ",
        default = initial_package
      }, function(package_input)
        if not package_input or package_input == "" then
          package_input = initial_package
        end

        -- Cria o arquivo com o template
        local template = java_templates[template_type]
        if template then
          -- Substitui o package no template
          local content = template:gsub("package com%.example;", "package " .. package_input .. ";")
          -- Substitui o nome da classe
          content = string.format(content, class_name)

          -- Cria na raiz do projeto inicialmente (para depois mover)
          local initial_filename = project_root .. "/" .. class_name .. ".java"

          -- Abre arquivo e escreve conteúdo
          vim.cmd("edit " .. vim.fn.fnameescape(initial_filename))
          vim.defer_fn(function()
            -- Garante que o buffer está modificável
            vim.bo.modifiable = true
            vim.bo.readonly = false

            -- Insere o conteúdo
            vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(content, "\n"))

            -- Salva inicialmente
            vim.cmd("write")

            -- Move para o local correto baseado no package e project_root
            local final_filename = move_file_to_package_location(initial_filename, package_input, project_root)

            vim.notify(string.format("✅ %s %s criada!\n📦 Package: %s\n📁 Local: %s",
              template_type, class_name, package_input, final_filename), vim.log.levels.INFO)
          end, 10)
        end
      end)
    end)
  end
end

-- Mapeamentos para templates Java básicos
map("n", "<leader>jc", create_java_file_with_template("class"), { desc = "Criar classe Java" })
map("n", "<leader>jr", create_java_file_with_template("record"), { desc = "Criar record Java" })
map("n", "<leader>ji", create_java_file_with_template("interface"), { desc = "Criar interface Java" })
map("n", "<leader>je", create_java_file_with_template("enum"), { desc = "Criar enum Java" })

-- Comando para criar arquivo Java no diretório atual
command("JavaNew", function(opts)
  local template_type = opts.args
  if not template_type or template_type == "" then
    vim.ui.select(vim.tbl_keys(java_templates), {
      prompt = "Selecione o tipo de arquivo Java:",
      format_item = function(item)
        return item
      end,
    }, function(choice)
      if choice then
        create_java_file_with_template(choice, true)()
      end
    end)
  elseif java_templates[template_type] then
    create_java_file_with_template(template_type, true)()
  else
    vim.notify("Tipo de template inválido: " .. template_type, vim.log.levels.ERROR)
  end
end, {
  desc = "Criar novo arquivo Java com template",
  nargs = "?",
  complete = function()
    return vim.tbl_keys(java_templates)
  end,
})

map("n", "<leader>e", "<CMD>KideTreeToggle<CR>", { desc = "Toggle Neo-tree", silent = true })

-- outline
map("n", "<leader>o", "<CMD>Outline<CR>", { desc = "Symbols Outline" })

-- task
command("TaskRun", function()
  require("kide.term").input_run(false)
end, { desc = "Task Run" })

command("TaskRunLast", function()
  require("kide.term").input_run(true)
end, { desc = "Restart Last Task" })

map("n", "<C-l>", function()
  require("conform").format({ lsp_fallback = true })
end, { desc = "format file" })
map("v", "<C-l>", function()
  vim.api.nvim_feedkeys("\027", "xt", false)
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")
  require("conform").format({
    range = {
      start = start_pos,
      ["end"] = end_pos,
    },
    lsp_fallback = true,
  })
end, { desc = "format range", silent = true, noremap = true })

-- Git
map("n", "]c", function()
  local gs = require("gitsigns")
  if vim.wo.diff then
    return "]c"
  end
  vim.schedule(function()
    gs.next_hunk()
  end)
  return "<Ignore>"
end, { expr = true, desc = "Git Next Hunk" })

map("n", "[c", function()
  local gs = require("gitsigns")
  if vim.wo.diff then
    return "[c"
  end
  vim.schedule(function()
    gs.prev_hunk()
  end)
  return "<Ignore>"
end, { expr = true, desc = "Git Prev Hunk" })

map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Jump to the previous diagnostic error" })
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Jump to the next diagnostic error" })
map("n", "go", vim.diagnostic.open_float, { desc = "Open float Diagnostics" })

-- quickfix next/prev
-- map("n", "]q", "<CMD>cnext<CR>", { desc = "Quickfix Next" })
-- map("n", "[q", "<CMD>cprev<CR>", { desc = "Quickfix Prev" })

-- local list next/prev
-- map("n", "]l", "<CMD>lnext<CR>", { desc = "Location List Next" })
-- map("n", "[l", "<CMD>lprev<CR>", { desc = "Location List Prev" })

command("InlayHint", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({}))
end, { desc = "LSP Inlay Hint" })
command("CodeLens", function()
  vim.lsp.codelens.refresh()
end, { desc = "LSP CodeLens" })
command("CodeLensClear", function()
  vim.lsp.codelens.clear()
end, { desc = "LSP CodeLens" })

command("LspDocumentSymbols", function(_)
  vim.lsp.buf.document_symbol()
end, {
  desc = "Lsp Document Symbols",
  nargs = 0,
  range = true,
})

command("LspWorkspaceSymbols", function(opts)
  if opts.range > 0 then
    local text = require("kide.tools").get_visual_selection()
    vim.lsp.buf.workspace_symbol(text[1])
  else
    vim.lsp.buf.workspace_symbol(opts.args)
  end
end, {
  desc = "Lsp Workspace Symbols",
  nargs = "?",
  range = true,
})

local severity_key = {
  "ERROR",
  "WARN",
  "INFO",
  "HINT",
}
command("DiagnosticsWorkspace", function(opts)
  local level = opts.args
  if level == nil or level == "" then
    vim.diagnostic.setqflist()
  else
    vim.diagnostic.setqflist({ severity = level })
  end
end, {
  desc = "Diagnostics Workspace",
  nargs = "?",
  complete = function(al, _, _)
    return vim.tbl_filter(function(item)
      return vim.startswith(item, al)
    end, severity_key)
  end,
})
command("DiagnosticsDocument", function(opts)
  local level = opts.args
  if level == nil or level == "" then
    vim.diagnostic.setloclist()
  else
    vim.diagnostic.setloclist({ severity = level })
  end
end, {
  desc = "Diagnostics Document",
  nargs = "?",
  complete = function(al, _, _)
    return vim.tbl_filter(function(item)
      return vim.startswith(item, al)
    end, severity_key)
  end,
})

-- find files
if vim.fn.executable("fd") == 1 then
  command("Fd", function(opt)
    vim.fn.setqflist({}, " ", { lines = vim.fn.systemlist("fd --type file " .. opt.args), efm = "%f" })
    vim.cmd("botright copen")
  end, {
    desc = "find files",
    nargs = "?",
  })
end
if vim.fn.executable("find") == 1 then
  command("Find", function(opt)
    vim.fn.setqflist({}, " ", { lines = vim.fn.systemlist("find . -type f -iname '" .. opt.args .. "'"), efm = "%f" })
    vim.cmd("botright copen")
  end, {
    desc = "find files",
    nargs = 1,
  })
end
command("CloseOtherBufs", function(_)
  local bufs = vim.api.nvim_list_bufs()
  local cur = vim.api.nvim_get_current_buf()
  for _, v in ipairs(bufs) do
    if vim.bo[v].buflisted and cur ~= v then
      local ok = pcall(vim.api.nvim_buf_delete, v, { force = false, unload = false })
      if not ok then
        vim.cmd("b " .. v)
        return
      end
    end
  end
end, {
  desc = "find files",
  nargs = 0,
})

map("n", "<leader>fq", function()
  Snacks.picker.qflist()
end, { desc = "Quickfix" })

map("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Find buffer" })
map("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Find files" })

map("n", "<leader>fd", function()
  Snacks.picker.diagnostics()
end, { desc = "Find diagnostics" })

map("v", "<leader>ff", function()
  vim.api.nvim_feedkeys("\027", "xt", false)
  local text = require("kide.tools").get_visual_selection()
  local param = text[1]
  Snacks.picker.files({ args = { param } })
end, { desc = "find files", silent = true, noremap = true })

map("v", "<leader>fw", function()
  vim.api.nvim_feedkeys("\027", "xt", false)
  local text = require("kide.tools").get_visual_selection()
  local param = text[1]
  Snacks.picker.grep({ search = param })
end, { desc = "live grep", silent = true, noremap = true })
map("n", "<leader>fw", function()
  Snacks.picker.grep()
end, { desc = "live grep", silent = true, noremap = true })

if vim.base64 then
  command("Base64Encode", function(opt)
    local text
    if opt.range > 0 then
      text = require("kide.tools").get_visual_selection()
      text = table.concat(text, "\n")
    else
      text = opt.args
    end
    vim.notify(vim.base64.encode(text), vim.log.levels.INFO)
  end, {
    desc = "base64 encode",
    nargs = "?",
    range = true,
  })
  command("Base64Decode", function(opt)
    local text
    if opt.range > 0 then
      text = require("kide.tools").get_visual_selection()
      text = table.concat(text, "\n")
    else
      text = opt.args
    end
    text = require("kide.tools").base64_url_safe_to_std(text)
    vim.notify(vim.base64.decode(text), vim.log.levels.INFO)
  end, {
    desc = "base64 decode",
    nargs = "?",
    range = true,
  })
end

local function creat_trans_command(name, from, to)
  command(name, function(opt)
    local text
    if opt.range > 0 then
      text = require("kide.tools").get_visual_selection()
      text = table.concat(text, "\n")
    else
      text = opt.args
    end
    require("kide.gpt.translate").translate_float({ text = text, from = from, to = to })
  end, {
    desc = "translate",
    nargs = "?",
    range = true,
  })
end

creat_trans_command("TransAutoZh", "auto", "中文")
map("v", "<leader>tc", function()
  vim.api.nvim_feedkeys("\027", "xt", false)
  local text = require("kide.tools").get_visual_selection()
  require("kide.gpt.translate").translate_float({ text = table.concat(text, "\n"), from = "auto", to = "中文" })
end, {})
creat_trans_command("TransEnZh", "英语", "中文")
creat_trans_command("TransZhEn", "中文", "英语")
creat_trans_command("TransIdZh", "印尼语", "中文")

command("GptChat", function(opt)
  local q
  local code
  if opt.range > 0 then
    code = require("kide.tools").get_visual_selection()
  end
  if opt.args and opt.args ~= "" then
    q = opt.args
  end
  require("kide.gpt.chat").toggle_gpt({
    code = code,
    question = q,
  })
end, {
  desc = "GptChat",
  nargs = "*",
  range = true,
})
command("GptLast", function(opt)
  require("kide.gpt.chat").toggle_gpt({
    last = true,
  })
end, {
  desc = "Gpt",
  nargs = "*",
  range = true,
})

command("Gpt", function(opt)
  local args = opt.args
  local code
  if opt.range > 0 then
    code = require("kide.tools").get_visual_selection()
  end
  if args and args ~= "" then
    if args == "linux" then
      require("kide.gpt.chat").toggle_gpt({
        gpt = require("kide.gpt.chat").linux,
        code = code,
      })
    elseif args == "lsp" then
      local cursor = vim.api.nvim_win_get_cursor(0)
      local diagnostics = vim.diagnostic.get(0, {
        lnum = cursor[1] - 1,
      })
      if #diagnostics > 0 then
        require("kide.gpt.chat").toggle_gpt({
          gpt = require("kide.gpt.chat").lsp,
          code = code,
          diagnostics = diagnostics,
        })
      else
        vim.notify("没有诊断信息", vim.log.levels.INFO)
      end
    else
      vim.notify("没有指定助手类型: " .. args, vim.log.levels.WARN)
    end
  else
    vim.notify("没有指定助手类型", vim.log.levels.WARN)
  end
end, {
  desc = "Gpt Assistant",
  nargs = 1,
  range = true,
  complete = function()
    return { "linux", "lsp" }
  end,
})

command("GptReasoner", function(opt)
  local q
  local code
  if opt.range > 0 then
    code = require("kide.tools").get_visual_selection()
  end
  if opt.args and opt.args ~= "" then
    q = opt.args
  end
  require("kide.gpt.chat").toggle_gpt({
    gpt = require("kide.gpt.chat").reasoner,
    code = code,
    question = q,
  })
end, {
  desc = "Gpt",
  nargs = "*",
  range = true,
})

command("GptProvider", function(opt)
  if opt.args and opt.args ~= "" then
    require("kide.gpt.provide").select_provide(opt.args)
  else
    vim.ui.select(require("kide.gpt.provide").provide_keys(), {
      prompt = "Select GPT Provides:",
      format_item = function(item)
        return item
      end,
    }, function(c)
      require("kide.gpt.provide").select_provide(c)
    end)
  end
end, {
  desc = "GptProvider",
  nargs = "?",
  range = false,
  complete = function()
    return require("kide.gpt.provide").provide_keys()
  end,
})

command("GptModels", function(_)
  vim.ui.select(require("kide.gpt.provide").models(), {
    prompt = "Select GPT Models:",
    format_item = function(item)
      return item
    end,
  }, function(c)
    require("kide.gpt.provide").select_model(c)
  end)
end, {
  desc = "GptModels",
  nargs = 0,
  range = false,
})

command("LspInfo", function(_)
  require("kide.lspui").open_info()
end, {
  desc = "Lsp info",
  nargs = 0,
  range = false,
})

command("NotificationHistory", function(_)
  Snacks.notifier.show_history()
end, {
  desc = "Notification History",
  nargs = 0,
  range = false,
})

command("LspLog", function(_)
  vim.cmd("tabedit " .. vim.lsp.log.get_filename())
  vim.cmd("normal! G")
end, {
  desc = "Lsp log",
  nargs = 0,
  range = false,
})

command("Go", function(opt)
  local cmd = { "go" }
  if opt.args and opt.args ~= "" then
    vim.list_extend(cmd, vim.split(opt.args, " "))
  end
  require("kide.term").toggle(cmd)
end, {
  desc = "Go cmd",
  nargs = "*",
  range = false,
  complete = "file",
})
command("ImageHover", function()
  Snacks.image.hover()
end, {
  desc = "Image Hover",
  nargs = 0,
  range = false,
})

if vim.fn.executable("cargo-owlsp") == 1 then
  map("n", "<A-o>", require("kide.lsp.rustowl").rustowl_cursor, { noremap = true, silent = true })
end

command("Codex", function()
  require("kide.codex").codex()
end, {
  desc = "Codex cmd",
  nargs = 0,
  range = false,
})

map({ "i", "n", "t" }, "<A;>", function()
  require("kide.codex").codex()
end, { desc = "Codex cmd" })

require("kide.tools").setup()
require("kide.tools.maven").setup()
require("kide.tools.plantuml").setup()
require("kide.tools.mermaid").setup()
require("kide.tools.curl").setup()
require("kide.gpt.commit").setup()
require("kide.gpt.code").setup()
