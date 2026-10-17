# Instalação de Agent Skills no Kilo Code

> Biblioteca central: 191 skills catalogadas. **Não instale todas automaticamente.** Este documento descreve instalação seletiva e verificação.

## Antes de instalar

- Confira a versão do Kilo Code instalada. As versões atuais documentam skills de projeto em `.kilo/skills/<nome>/SKILL.md` e globais em `~/.kilo/skills/<nome>/SKILL.md`.
- Versões antigas podem usar `.kilocode/skills/`. Verifique qual estrutura sua extensão reconhece.
- **Não execute** scripts ou comandos embutidos em skills desconhecidas sem revisão.
- Faça backup e use um projeto de teste; não comece pelo BarberOS ou Tapeçaria Bugão.

Referência: https://kilo.ai/docs/customize/skills

## Obter a biblioteca

```powershell
git clone https://github.com/eullerfunes/AI-FullStack-Skills.git
cd AI-FullStack-Skills
```

A biblioteca usa `skills/<categoria>/<origem>/<skill>/<diretorio-original>/SKILL.md` em alguns casos. **Não copie a pasta de categoria inteira diretamente para o diretório do Kilo.** Cada skill deve terminar em `<diretorio-de-skills>/<nome-da-skill>/SKILL.md`.

## Teste de instalação seletiva (PowerShell)

Execute no diretório da biblioteca depois de revisar o arquivo de origem:

```powershell
$source = 'skills/agents/obra-superpowers/brainstorming/brainstorming'
$targetRoot = Join-Path $HOME '.kilo/skills'
$target = Join-Path $targetRoot 'brainstorming'

if (!(Test-Path (Join-Path $source 'SKILL.md'))) { throw 'SKILL.md não encontrado na origem' }
if (Test-Path $target) { throw "Destino existente; nenhuma substituição efetuada: $target" }

New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null
Copy-Item -Path $source -Destination $target -Recurse
Test-Path (Join-Path $target 'SKILL.md')
```

Este exemplo instala **apenas a skill brainstorming** globalmente, sem sobrescrever versões pré-existentes. A skill tem instruções próprias e deve ser revisada antes de uso.

Se preferir uma instalação exclusiva de um projeto de teste, substitua `$targetRoot` por `'<diretorio-do-projeto>/.kilo/skills'`.

## Verificação no Kilo

1. Abra um projeto de teste e inicie uma sessão nova, ou use `/reload` quando disponível.
2. Consulte as skills oferecidas pelo Kilo; na interface nova, elas aparecem também no menu `/`.
3. Peça explicitamente para o Kilo mostrar/usar a skill `brainstorming` e confirme que ele localiza o SKILL.md instalado.
4. Verifique se o nome no frontmatter é idêntico ao nome da pasta imediata.

**Importante:** a presença no `CATALOG.json` não garante que a skill foi descoberta ou está compatível. Uma skill pode exigir ferramentas, permissões ou dependências adicionais.

## Pendências da biblioteca (auditoria inicial)

- Conferir o catálogo completo: há campos `author`, `version` e `license` nulos em alguns itens e caminhos com separador Windows.
- Validar nomes, descrição e correspondência pasta/frontmatter, detectar duplicações e licenças específicas.
- Padronizar o empacotamento de cada skill para instalação direta sem níveis extras de pastas.
- O `UPDATE.md` refere-se a `import-skills.ps1` e `gen-catalog.ps1`, **não encontrados na raiz do repositório durante a verificação inicial**; localizar ou adicionar scripts auditados antes de executar o procedimento de atualização.
- Testar reconhecimento e execução real em Kilo Code local. **Ainda não homologado**.

## Campo invocation_name no CATALOG.json

Cada entrada do `CATALOG.json` inclui o campo `invocation_name`, extraído do frontmatter `name` do respectivo `SKILL.md` na origem. Esse campo indica o nome pelo qual a skill deve ser invocada no Kilo Code e pode divergir do nome do diretório de instalação (`skill`).

Exemplo de divergência documentada:

| id | diretório (skill) | invocation_name (frontmatter) |
|---|---|---|
| `vercel-labs-agent-skills/react-best-practices` | `react-best-practices` | `vercel-react-best-practices` |
| `trailofbits-skills/code-improver` | `code-improver` | `skill-improver` |

Ao instalar, o diretório de destino usa o nome `skill` (a pasta). O Kilo Code deve ser acionado pelo `invocation_name`. Quando duas skills compartilham o mesmo `invocation_name` (ex.: `brand-guidelines` em `getsentry-skills` e `anthropics-skills`), o instalador usa o nome qualificado pela origem (ex.: `getsentry-skills-brand-guidelines`) para evitar sobreposição.

## Remoção

Remova somente a pasta da skill que instalou (no exemplo, `~/.kilo/skills/brainstorming`). Não remova a pasta `skills` inteira se contiver outras skills.

## Atualizações

Revise `UPDATE.md`, compare alterações com a fonte original e não sobrescreva instalações sem backup, teste e aprovação.
