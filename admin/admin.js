(function () {
  "use strict";

  const statusEl = document.querySelector("#status");
  const defaultLanguageSelect = document.querySelector("#defaultLanguage");
  const languageRows = document.querySelector("#languageRows");
  const uiTableHead = document.querySelector("#uiTable thead");
  const uiTableBody = document.querySelector("#uiTable tbody");
  const categoryRows = document.querySelector("#categoryRows");
  const questionCategorySelect = document.querySelector("#questionCategorySelect");
  const questionRows = document.querySelector("#questionRows");

  const state = {
    pack: null,
    selectedCategoryId: null
  };

  function setStatus(message, isError) {
    statusEl.textContent = message || "";
    statusEl.classList.toggle("error", Boolean(isError));
  }

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  async function loadPack() {
    const response = await fetch("./content/content.json", { cache: "no-store" });
    if (!response.ok) {
      throw new Error("Could not load content/content.json");
    }
    state.pack = await response.json();
    if (!Array.isArray(state.pack.languages) || !state.pack.languages.length) {
      throw new Error("Content pack has no languages");
    }
    if (!state.pack.ui) state.pack.ui = {};
    if (!Array.isArray(state.pack.categories)) state.pack.categories = [];
    if (!state.pack.defaultLanguage) {
      state.pack.defaultLanguage = state.pack.languages[0].code;
    }
    state.selectedCategoryId = state.pack.categories[0]?.id || null;
    renderAll();
    setStatus("Loaded content pack.");
  }

  function currentLanguages() {
    return state.pack.languages;
  }

  function ensureLabelMaps() {
    currentLanguages().forEach((language) => {
      Object.keys(state.pack.ui).forEach((key) => {
        if (typeof state.pack.ui[key][language.code] !== "string") {
          state.pack.ui[key][language.code] = state.pack.ui[key][state.pack.defaultLanguage] || "";
        }
      });
      state.pack.categories.forEach((category) => {
        if (!category.labels) category.labels = {};
        if (typeof category.labels[language.code] !== "string") {
          category.labels[language.code] = category.labels[state.pack.defaultLanguage] || category.id;
        }
      });
    });
  }

  function renderTabs() {
    document.querySelectorAll(".tab").forEach((button) => {
      button.addEventListener("click", () => {
        document.querySelectorAll(".tab").forEach((tab) => tab.classList.remove("active"));
        document.querySelectorAll(".panel").forEach((panel) => panel.classList.remove("active"));
        button.classList.add("active");
        document.querySelector(`#panel-${button.dataset.tab}`).classList.add("active");
      });
    });
  }

  function renderDefaultLanguage() {
    defaultLanguageSelect.innerHTML = currentLanguages()
      .map((language) => `<option value="${escapeHtml(language.code)}">${escapeHtml(language.name)} (${escapeHtml(language.code)})</option>`)
      .join("");
    defaultLanguageSelect.value = state.pack.defaultLanguage;
  }

  function renderLanguages() {
    renderDefaultLanguage();
    languageRows.innerHTML = "";
    currentLanguages().forEach((language, index) => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <div class="grid-2">
          <label>Code<input data-field="code" value="${escapeAttr(language.code)}"></label>
          <label>Name<input data-field="name" value="${escapeAttr(language.name)}"></label>
        </div>
        <div class="row-actions">
          <button type="button" class="ghost" data-action="delete">Delete</button>
        </div>
      `;
      card.querySelector('[data-field="code"]').addEventListener("change", (event) => {
        const oldCode = language.code;
        const nextCode = sanitizeCode(event.target.value);
        if (!nextCode) {
          event.target.value = oldCode;
          return;
        }
        if (currentLanguages().some((entry, i) => i !== index && entry.code === nextCode)) {
          setStatus("Language code already exists.", true);
          event.target.value = oldCode;
          return;
        }
        renameLanguageCode(oldCode, nextCode);
        language.code = nextCode;
        if (state.pack.defaultLanguage === oldCode) {
          state.pack.defaultLanguage = nextCode;
        }
        renderAll();
        setStatus(`Renamed language ${oldCode} → ${nextCode}.`);
      });
      card.querySelector('[data-field="name"]').addEventListener("input", (event) => {
        language.name = event.target.value.trim() || language.code;
      });
      card.querySelector('[data-action="delete"]').addEventListener("click", () => {
        if (currentLanguages().length <= 1) {
          setStatus("Keep at least one language.", true);
          return;
        }
        const removed = state.pack.languages.splice(index, 1)[0];
        Object.keys(state.pack.ui).forEach((key) => {
          delete state.pack.ui[key][removed.code];
        });
        state.pack.categories.forEach((category) => {
          delete category.labels[removed.code];
        });
        if (state.pack.defaultLanguage === removed.code) {
          state.pack.defaultLanguage = state.pack.languages[0].code;
        }
        renderAll();
        setStatus(`Removed language ${removed.code}.`);
      });
      languageRows.append(card);
    });
  }

  function renameLanguageCode(oldCode, nextCode) {
    Object.keys(state.pack.ui).forEach((key) => {
      state.pack.ui[key][nextCode] = state.pack.ui[key][oldCode] || "";
      delete state.pack.ui[key][oldCode];
    });
    state.pack.categories.forEach((category) => {
      category.labels[nextCode] = category.labels[oldCode] || category.id;
      delete category.labels[oldCode];
    });
  }

  function renderUiTable() {
    const languages = currentLanguages();
    uiTableHead.innerHTML = `<tr><th>Key</th>${languages.map((language) => `<th>${escapeHtml(language.code)}</th>`).join("")}<th></th></tr>`;
    uiTableBody.innerHTML = "";
    Object.keys(state.pack.ui)
      .sort()
      .forEach((key) => {
        const row = document.createElement("tr");
        const cells = languages
          .map((language) => {
            const value = state.pack.ui[key][language.code] || "";
            return `<td><input data-key="${escapeAttr(key)}" data-lang="${escapeAttr(language.code)}" value="${escapeAttr(value)}"></td>`;
          })
          .join("");
        row.innerHTML = `<td><code>${escapeHtml(key)}</code></td>${cells}<td><button type="button" class="ghost" data-delete-key="${escapeAttr(key)}">Delete</button></td>`;
        row.querySelectorAll("input").forEach((input) => {
          input.addEventListener("input", () => {
            state.pack.ui[input.dataset.key][input.dataset.lang] = input.value;
          });
        });
        row.querySelector("button").addEventListener("click", () => {
          delete state.pack.ui[key];
          renderUiTable();
          setStatus(`Removed UI key ${key}.`);
        });
        uiTableBody.append(row);
      });
  }

  function renderCategories() {
    categoryRows.innerHTML = "";
    state.pack.categories.forEach((category, index) => {
      const card = document.createElement("div");
      card.className = `card${category.id === state.selectedCategoryId ? " selected" : ""}`;
      const labelFields = currentLanguages()
        .map((language) => {
          const value = category.labels?.[language.code] || "";
          return `<label>${escapeHtml(language.name)} label<input data-lang="${escapeAttr(language.code)}" value="${escapeAttr(value)}"></label>`;
        })
        .join("");
      card.innerHTML = `
        <div class="grid-2">
          <label>ID<input data-field="id" value="${escapeAttr(category.id)}"></label>
          <label>Questions<strong>${category.questions?.length || 0}</strong></label>
        </div>
        <div class="grid-2">${labelFields}</div>
        <div class="row-actions">
          <button type="button" class="secondary" data-action="select">Edit questions</button>
          <button type="button" class="ghost" data-action="delete">Delete</button>
        </div>
      `;
      card.querySelector('[data-field="id"]').addEventListener("change", (event) => {
        const nextId = sanitizeCode(event.target.value);
        if (!nextId) {
          event.target.value = category.id;
          return;
        }
        if (state.pack.categories.some((entry, i) => i !== index && entry.id === nextId)) {
          setStatus("Category ID already exists.", true);
          event.target.value = category.id;
          return;
        }
        if (state.selectedCategoryId === category.id) {
          state.selectedCategoryId = nextId;
        }
        category.id = nextId;
        renderQuestions();
        setStatus(`Category id set to ${nextId}.`);
      });
      card.querySelectorAll("input[data-lang]").forEach((input) => {
        input.addEventListener("input", () => {
          category.labels[input.dataset.lang] = input.value;
        });
      });
      card.querySelector('[data-action="select"]').addEventListener("click", () => {
        state.selectedCategoryId = category.id;
        document.querySelector('.tab[data-tab="questions"]').click();
        renderCategories();
        renderQuestions();
      });
      card.querySelector('[data-action="delete"]').addEventListener("click", () => {
        state.pack.categories.splice(index, 1);
        if (state.selectedCategoryId === category.id) {
          state.selectedCategoryId = state.pack.categories[0]?.id || null;
        }
        renderAll();
        setStatus("Category deleted.");
      });
      categoryRows.append(card);
    });
  }

  function selectedCategory() {
    return state.pack.categories.find((category) => category.id === state.selectedCategoryId) || null;
  }

  function renderQuestions() {
    questionCategorySelect.innerHTML = state.pack.categories
      .map((category) => {
        const label = category.labels?.[state.pack.defaultLanguage] || category.id;
        return `<option value="${escapeAttr(category.id)}">${escapeHtml(label)}</option>`;
      })
      .join("");
    if (state.selectedCategoryId) {
      questionCategorySelect.value = state.selectedCategoryId;
    }
    const category = selectedCategory();
    questionRows.innerHTML = "";
    if (!category) {
      questionRows.innerHTML = `<p class="status">No category selected.</p>`;
      return;
    }
    category.questions = category.questions || [];
    category.questions.forEach((question, index) => {
      const card = document.createElement("div");
      card.className = "card";
      card.innerHTML = `
        <label>Prompt<textarea data-field="prompt">${escapeHtml(question.prompt || "")}</textarea></label>
        <label>Suggested answer<textarea data-field="answer">${escapeHtml(question.answer || "")}</textarea></label>
        <div class="row-actions">
          <button type="button" class="ghost" data-action="delete">Delete</button>
        </div>
      `;
      card.querySelector('[data-field="prompt"]').addEventListener("input", (event) => {
        question.prompt = event.target.value;
      });
      card.querySelector('[data-field="answer"]').addEventListener("input", (event) => {
        question.answer = event.target.value;
      });
      card.querySelector('[data-action="delete"]').addEventListener("click", () => {
        category.questions.splice(index, 1);
        renderQuestions();
        renderCategories();
      });
      questionRows.append(card);
    });
  }

  function renderAll() {
    ensureLabelMaps();
    renderLanguages();
    renderUiTable();
    renderCategories();
    renderQuestions();
  }

  function sanitizeCode(value) {
    return String(value || "")
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9-_]/g, "-")
      .replace(/-+/g, "-");
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function escapeAttr(value) {
    return escapeHtml(value).replaceAll("'", "&#39;");
  }

  const STORAGE_KEYS = {
    repo: "lr-admin-repo",
    branch: "lr-admin-branch",
    token: "lr-admin-token"
  };

  const DEFAULT_REPO = "spirea89/LanguageSpinApple";
  const DEFAULT_BRANCH = "main";
  const CONTENT_PATHS = [
    "content/content.json",
    "admin/content/content.json",
    "LanguageRoulette/Resources/content/content.json"
  ];

  const githubRepoInput = document.querySelector("#githubRepo");
  const githubBranchInput = document.querySelector("#githubBranch");
  const githubTokenInput = document.querySelector("#githubToken");

  function isLocalHost() {
    const host = window.location.hostname;
    return host === "localhost" || host === "127.0.0.1";
  }

  function loadGithubSettings() {
    githubRepoInput.value = localStorage.getItem(STORAGE_KEYS.repo) || DEFAULT_REPO;
    githubBranchInput.value = localStorage.getItem(STORAGE_KEYS.branch) || DEFAULT_BRANCH;
    githubTokenInput.value = localStorage.getItem(STORAGE_KEYS.token) || "";
  }

  function saveGithubSettings() {
    localStorage.setItem(STORAGE_KEYS.repo, githubRepoInput.value.trim() || DEFAULT_REPO);
    localStorage.setItem(STORAGE_KEYS.branch, githubBranchInput.value.trim() || DEFAULT_BRANCH);
    const token = githubTokenInput.value.trim();
    if (token) {
      localStorage.setItem(STORAGE_KEYS.token, token);
    }
    setStatus("GitHub settings saved in this browser.");
  }

  function clearGithubToken() {
    localStorage.removeItem(STORAGE_KEYS.token);
    githubTokenInput.value = "";
    setStatus("GitHub token cleared from this browser.");
  }

  function getGithubSettings() {
    return {
      repo: (githubRepoInput.value || localStorage.getItem(STORAGE_KEYS.repo) || DEFAULT_REPO).trim(),
      branch: (githubBranchInput.value || localStorage.getItem(STORAGE_KEYS.branch) || DEFAULT_BRANCH).trim(),
      token: (githubTokenInput.value || localStorage.getItem(STORAGE_KEYS.token) || "").trim()
    };
  }

  async function githubApi(path, { method = "GET", token, body } = {}) {
    const response = await fetch(`https://api.github.com${path}`, {
      method,
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${token}`,
        "X-GitHub-Api-Version": "2022-11-28",
        ...(body ? { "Content-Type": "application/json" } : {})
      },
      body: body ? JSON.stringify(body) : undefined
    });
    const text = await response.text();
    let data = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch (_error) {
      data = { message: text };
    }
    if (!response.ok) {
      throw new Error(data?.message || `GitHub API error (${response.status})`);
    }
    return data;
  }

  function utf8ToBase64(text) {
    const bytes = new TextEncoder().encode(text);
    let binary = "";
    bytes.forEach((byte) => {
      binary += String.fromCharCode(byte);
    });
    return btoa(binary);
  }

  async function savePackToGithub() {
    const { repo, branch, token } = getGithubSettings();
    if (!repo.includes("/")) {
      throw new Error("Repository must look like owner/name.");
    }
    if (!token) {
      throw new Error("Add a GitHub personal access token with Contents write access, then click Remember settings.");
    }

    const pretty = `${JSON.stringify(state.pack, null, 2)}\n`;
    const encoded = utf8ToBase64(pretty);
    const [owner, name] = repo.split("/");

    const ref = await githubApi(`/repos/${owner}/${name}/git/ref/heads/${encodeURIComponent(branch)}`, { token });
    const latestCommitSha = ref.object.sha;
    const latestCommit = await githubApi(`/repos/${owner}/${name}/git/commits/${latestCommitSha}`, { token });
    const baseTreeSha = latestCommit.tree.sha;

    const tree = [];
    for (const filePath of CONTENT_PATHS) {
      const blob = await githubApi(`/repos/${owner}/${name}/git/blobs`, {
        method: "POST",
        token,
        body: { content: encoded, encoding: "base64" }
      });
      tree.push({
        path: filePath,
        mode: "100644",
        type: "blob",
        sha: blob.sha
      });
    }

    const newTree = await githubApi(`/repos/${owner}/${name}/git/trees`, {
      method: "POST",
      token,
      body: {
        base_tree: baseTreeSha,
        tree
      }
    });

    const newCommit = await githubApi(`/repos/${owner}/${name}/git/commits`, {
      method: "POST",
      token,
      body: {
        message: "Update Language Roulette content pack from admin",
        tree: newTree.sha,
        parents: [latestCommitSha]
      }
    });

    await githubApi(`/repos/${owner}/${name}/git/refs/heads/${encodeURIComponent(branch)}`, {
      method: "PATCH",
      token,
      body: { sha: newCommit.sha }
    });

    return newCommit.sha;
  }

  async function savePackLocally() {
    const response = await fetch("/api/save-content", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(state.pack)
    });
    if (!response.ok) {
      const text = await response.text();
      throw new Error(text || "Local save failed");
    }
  }

  function downloadPack() {
    const blob = new Blob([JSON.stringify(state.pack, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = "content.json";
    anchor.click();
    URL.revokeObjectURL(url);
    setStatus("Downloaded content.json.");
  }

  async function savePack() {
    setStatus("Saving...");
    try {
      if (isLocalHost()) {
        try {
          await savePackLocally();
          setStatus("Saved locally to content/, admin/content/, and LanguageRoulette/Resources/content/.");
          return;
        } catch (_localError) {
          // Fall through to GitHub save when local API is unavailable.
        }
      }

      const sha = await savePackToGithub();
      setStatus(`Saved to GitHub (${sha.slice(0, 7)}). Pull on your Mac, then rebuild the iOS app.`);
    } catch (error) {
      setStatus(error.message || "Save failed", true);
    }
  }

  document.querySelector("#addLanguageButton").addEventListener("click", () => {
    const code = window.prompt("New language code (example: fr)", "fr");
    const sanitized = sanitizeCode(code || "");
    if (!sanitized) return;
    if (currentLanguages().some((language) => language.code === sanitized)) {
      setStatus("Language already exists.", true);
      return;
    }
    const name = window.prompt("Language display name", sanitized.toUpperCase()) || sanitized;
    state.pack.languages.push({ code: sanitized, name });
    ensureLabelMaps();
    renderAll();
    setStatus(`Added language ${sanitized}. Fill UI strings and category labels next.`);
  });

  document.querySelector("#addUiKeyButton").addEventListener("click", () => {
    const key = window.prompt("UI string key (example: navHelp)");
    const sanitized = String(key || "").trim();
    if (!sanitized) return;
    if (state.pack.ui[sanitized]) {
      setStatus("UI key already exists.", true);
      return;
    }
    state.pack.ui[sanitized] = {};
    currentLanguages().forEach((language) => {
      state.pack.ui[sanitized][language.code] = "";
    });
    renderUiTable();
  });

  document.querySelector("#addCategoryButton").addEventListener("click", () => {
    const id = sanitizeCode(window.prompt("Category id (example: weather)", `category-${state.pack.categories.length + 1}`) || "");
    if (!id) return;
    if (state.pack.categories.some((category) => category.id === id)) {
      setStatus("Category already exists.", true);
      return;
    }
    const labels = {};
    currentLanguages().forEach((language) => {
      labels[language.code] = id;
    });
    state.pack.categories.push({
      id,
      labels,
      questions: [{ prompt: "Neue Frage?", answer: "" }]
    });
    state.selectedCategoryId = id;
    renderAll();
  });

  document.querySelector("#addQuestionButton").addEventListener("click", () => {
    const category = selectedCategory();
    if (!category) return;
    category.questions.push({ prompt: "", answer: "" });
    renderQuestions();
    renderCategories();
  });

  questionCategorySelect.addEventListener("change", () => {
    state.selectedCategoryId = questionCategorySelect.value;
    renderCategories();
    renderQuestions();
  });

  defaultLanguageSelect.addEventListener("change", () => {
    state.pack.defaultLanguage = defaultLanguageSelect.value;
    setStatus(`Default language set to ${state.pack.defaultLanguage}.`);
  });

  document.querySelector("#downloadButton").addEventListener("click", downloadPack);
  document.querySelector("#saveButton").addEventListener("click", savePack);
  document.querySelector("#reloadButton").addEventListener("click", () => {
    loadPack().catch((error) => setStatus(error.message, true));
  });
  document.querySelector("#saveGithubSettings").addEventListener("click", saveGithubSettings);
  document.querySelector("#clearGithubToken").addEventListener("click", clearGithubToken);

  loadGithubSettings();
  renderTabs();
  loadPack().catch((error) => setStatus(error.message, true));
})();
