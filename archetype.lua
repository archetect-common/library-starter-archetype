local context = Context.new()

context:prompt_text("Library Description:", "description", {
    placeholder = "Common utility templates",
    help = "Short human-readable description of the library's purpose.",
})

context:prompt_text("Library Name:", "archetype_name", {
    help = "Used as the repo name. Will be suffixed with -library.",
})

context:prompt_text("Author:", "author_full", {
    placeholder = "Your Name <you@example.com>",
    default = "Your Name <you@example.com>",
})

local repo_name = context:get("archetype_name") .. "-library"
context:set("repo_name", repo_name)

context:prompt_multi_select("Library Contents:", "library_contents",
    { "includes (ATL template partials)", "lib (Lua modules)" },
    {
        default = { "includes (ATL template partials)" },
        help = "Select what your library will provide. Most libraries have includes/; some also have lib/.",
    })

-- Source control
context:prompt_select("Source Control:", "scm_provider",
    { "None", "GitHub (Instructions)", "GitHub (Publish)" },
    { default = "GitHub (Instructions)" })

local scm = context:get("scm_provider")
local uses_github = scm == "GitHub (Instructions)" or scm == "GitHub (Publish)"

if uses_github then
    context:prompt_text("GitHub Organization:", "organization", {
        placeholder = "your-org or username",
        default = "your-org",
    })
end

if scm == "GitHub (Publish)" then
    local token = os.getenv("GITHUB_TOKEN")
    if not token or token == "" then
        log.warn("GITHUB_TOKEN is not set. Falling back to GitHub (Instructions) mode.")
        scm = "GitHub (Instructions)"
        context:set("scm_provider", scm)
    end
end

if uses_github then
    context:set("github_slug", context:get("organization") .. "/" .. repo_name)
end

-- Render base
directory.render("contents/minimal", context)

-- Conditionally add includes/ and lib/ sample content
local contents = context:get("library_contents") or {}
local has_includes = false
local has_lib = false
for _, item in ipairs(contents) do
    if item:match("^includes") then has_includes = true end
    if item:match("^lib") then has_lib = true end
end

if has_includes then
    directory.render("contents/includes-sample", context, { if_exists = Existing.Overwrite })
end

if has_lib then
    directory.render("contents/lib-sample", context, { if_exists = Existing.Overwrite })
end

if uses_github then
    directory.render("contents/github", context)
end

-- Git init
local git = require("archetect.git")
local repo = git.init(repo_name, { branch = "main" })
repo:add_all()
repo:commit("initial commit")

-- Publish
if scm == "GitHub (Publish)" then
    local github = require("archetect.github")
    local slug = context:get("github_slug")
    if github.create_repo(slug, { visibility = "public" }) then
        repo:remote_add("origin", "git@github.com:" .. slug .. ".git")
        repo:push("origin", "main")
        log.info("Published to https://github.com/" .. slug)
    end
elseif scm == "GitHub (Instructions)" then
    local slug = context:get("github_slug")
    log.info("")
    log.info("Next steps:")
    log.info("  cd " .. repo_name)
    log.info("  gh repo create " .. slug .. " --public --source=. --remote=origin")
    log.info("  git push -u origin HEAD")
    log.info("")
elseif scm == "None" then
    log.info("")
    log.info("Local library created at ./" .. repo_name)
    log.info("")
end
