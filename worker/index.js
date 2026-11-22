// worker/index.js
// Cloudflare Worker: spanani Store IPA Uploader & Publisher

const HTML_PAGE = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <title>spanani Store &mdash; Publish IPA</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      background-color: #0f0f0f;
      color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
      -webkit-font-smoothing: antialiased;
    }
    .container {
      width: 100%;
      max-width: 520px;
    }
    .card {
      background: #18181b;
      border: 1px solid #27272a;
      border-radius: 16px;
      padding: 28px;
      box-shadow: 0 16px 40px rgba(0, 0, 0, 0.7);
    }
    .header {
      text-align: center;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-block;
      background: rgba(153, 85, 231, 0.18);
      color: #b27bf3;
      border: 1px solid rgba(153, 85, 231, 0.4);
      padding: 4px 12px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 600;
      letter-spacing: 0.5px;
      margin-bottom: 12px;
      text-transform: uppercase;
    }
    .header h1 {
      font-size: 24px;
      font-weight: 700;
      letter-spacing: -0.5px;
      margin-bottom: 6px;
    }
    .header h1 span {
      color: #9955E7;
    }
    .header p {
      color: #a1a1aa;
      font-size: 14px;
      line-height: 1.4;
    }
    form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .form-group {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .form-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    @media (max-width: 480px) {
      .form-row {
        grid-template-columns: 1fr;
      }
      .card {
        padding: 22px 18px;
      }
    }
    label {
      font-size: 13px;
      font-weight: 600;
      color: #e4e4e7;
    }
    .opt {
      color: #71717a;
      font-weight: 400;
    }
    input[type="text"],
    input[type="password"],
    select,
    textarea {
      width: 100%;
      background: #0d0d10;
      border: 1px solid #2f2f38;
      border-radius: 10px;
      color: #ffffff;
      padding: 12px 14px;
      font-size: 16px; /* 16px prevents iOS Safari auto-zoom */
      font-family: inherit;
      transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }
    input[type="text"]:focus,
    input[type="password"]:focus,
    select:focus,
    textarea:focus {
      outline: none;
      border-color: #9955E7;
      box-shadow: 0 0 0 3px rgba(153, 85, 231, 0.25);
    }
    select {
      appearance: none;
      background-image: url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%239955E7%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5-1.9-9.2-5.4-12.8z%22%2F%3E%3C%2Fsvg%3E');
      background-repeat: no-repeat;
      background-position: right 14px center;
      background-size: 10px auto;
      padding-right: 36px;
      cursor: pointer;
    }
    textarea {
      resize: vertical;
      min-height: 70px;
    }
    .file-dropzone {
      position: relative;
      border: 2px dashed #3f3f46;
      border-radius: 12px;
      padding: 22px 16px;
      text-align: center;
      background: #0d0d10;
      cursor: pointer;
      transition: border-color 0.2s, background 0.2s;
    }
    .file-dropzone:hover {
      border-color: #9955E7;
      background: rgba(153, 85, 231, 0.05);
    }
    .file-dropzone input[type="file"] {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      opacity: 0;
      cursor: pointer;
    }
    .file-text {
      font-size: 15px;
      font-weight: 500;
      color: #e4e4e7;
      word-break: break-all;
    }
    .file-hint {
      font-size: 12px;
      color: #71717a;
      margin-top: 4px;
    }
    .submit-btn {
      margin-top: 8px;
      background: #9955E7;
      color: #ffffff;
      border: none;
      border-radius: 10px;
      padding: 15px 20px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      width: 100%;
      transition: background 0.2s, transform 0.1s, opacity 0.2s;
    }
    .submit-btn:hover:not(:disabled) {
      background: #8443d3;
    }
    .submit-btn:active:not(:disabled) {
      transform: scale(0.99);
    }
    .submit-btn:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    .progress-section {
      margin-top: 6px;
    }
    .progress-track {
      width: 100%;
      height: 8px;
      background: #27272a;
      border-radius: 4px;
      overflow: hidden;
    }
    .progress-bar {
      height: 100%;
      width: 0%;
      background: linear-gradient(90deg, #9955E7, #b27bf3);
      transition: width 0.15s ease;
    }
    .progress-status {
      font-size: 12px;
      color: #a1a1aa;
      text-align: center;
      margin-top: 6px;
    }
    .result-box {
      border-radius: 12px;
      padding: 16px;
      font-size: 14px;
      line-height: 1.5;
      margin-top: 8px;
    }
    .result-success {
      background: rgba(153, 85, 231, 0.12);
      border: 1px solid #9955E7;
      color: #e9d5ff;
    }
    .result-error {
      background: rgba(239, 68, 68, 0.12);
      border: 1px solid #ef4444;
      color: #fca5a5;
    }
    .result-title {
      font-weight: 700;
      font-size: 15px;
      margin-bottom: 4px;
    }
    .result-desc {
      font-size: 13px;
      opacity: 0.95;
    }
    .result-link {
      margin-top: 10px;
    }
    .result-link a {
      color: #d8b4fe;
      text-decoration: underline;
      font-weight: 600;
      word-break: break-all;
    }
    .hidden {
      display: none !important;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="header">
        <div class="badge">spanani Store</div>
        <h1>Publish <span>IPA</span></h1>
        <p>Upload iOS packages directly to GitHub &amp; the spanani AltStore source.</p>
      </div>

      <form id="uploadForm">
        <div class="form-group">
          <label for="password">Upload Password *</label>
          <input type="password" id="password" name="password" required autocomplete="current-password" placeholder="Enter owner password">
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="name">App Name *</label>
            <input type="text" id="name" name="name" required placeholder="e.g. FMHY">
          </div>
          <div class="form-group">
            <label for="bundleId">Bundle ID *</label>
            <input type="text" id="bundleId" name="bundleId" required placeholder="e.g. de.spanani.fmhy">
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="version">Version *</label>
            <input type="text" id="version" name="version" required placeholder="e.g. 1.0.0">
          </div>
          <div class="form-group">
            <label for="category">Category *</label>
            <select id="category" name="category">
              <option value="utilities">utilities</option>
              <option value="games">games</option>
              <option value="social">social</option>
              <option value="entertainment">entertainment</option>
              <option value="productivity">productivity</option>
              <option value="other">other</option>
            </select>
          </div>
        </div>

        <div class="form-group">
          <label for="release">Release Type *</label>
          <select id="release" name="release">
            <option value="latest">latest (own release)</option>
            <option value="community">community (community release)</option>
          </select>
        </div>

        <div class="form-group">
          <label for="subtitle">Subtitle <span class="opt">(optional)</span></label>
          <input type="text" id="subtitle" name="subtitle" placeholder="Short tagline, e.g. Wiki &amp; link checker">
        </div>

        <div class="form-group">
          <label for="description">Description <span class="opt">(optional)</span></label>
          <textarea id="description" name="description" rows="3" placeholder="App description or release notes..."></textarea>
        </div>

        <div class="form-group">
          <label for="ipa">IPA File (.ipa only) *</label>
          <div class="file-dropzone" id="dropzone">
            <input type="file" id="ipa" name="ipa" accept=".ipa" required>
            <div class="file-text" id="fileText">Tap or click to select .ipa file</div>
            <div class="file-hint">Maximum file size: 500 MB</div>
          </div>
        </div>

        <div id="progressSection" class="progress-section hidden">
          <div class="progress-track">
            <div id="progressBar" class="progress-bar"></div>
          </div>
          <div id="progressStatus" class="progress-status">Uploading: 0%</div>
        </div>

        <div id="resultBox" class="result-box hidden"></div>

        <button type="submit" id="submitBtn" class="submit-btn">Publish to Store</button>
      </form>
    </div>
  </div>

  <script>
    (function() {
      var form = document.getElementById('uploadForm');
      var fileInput = document.getElementById('ipa');
      var fileText = document.getElementById('fileText');
      var passwordInput = document.getElementById('password');
      var progressSection = document.getElementById('progressSection');
      var progressBar = document.getElementById('progressBar');
      var progressStatus = document.getElementById('progressStatus');
      var resultBox = document.getElementById('resultBox');
      var submitBtn = document.getElementById('submitBtn');

      try {
        var savedPass = localStorage.getItem('spanani_upload_pass');
        if (savedPass) {
          passwordInput.value = savedPass;
        }
      } catch (_) {}

      passwordInput.addEventListener('input', function() {
        try {
          localStorage.setItem('spanani_upload_pass', passwordInput.value);
        } catch (_) {}
      });

      fileInput.addEventListener('change', function() {
        if (fileInput.files && fileInput.files[0]) {
          var f = fileInput.files[0];
          fileText.textContent = f.name + ' (' + formatBytes(f.size) + ')';
        } else {
          fileText.textContent = 'Tap or click to select .ipa file';
        }
      });

      function formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        var k = 1024;
        var sizes = ['B', 'KB', 'MB', 'GB'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
      }

      function escapeHtml(str) {
        return String(str).replace(/[&<>"']/g, function(m) {
          return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m];
        });
      }

      function showResult(isSuccess, title, desc, linkUrl) {
        resultBox.className = 'result-box ' + (isSuccess ? 'result-success' : 'result-error');
        var html = '<div class="result-title">' + escapeHtml(title) + '</div>';
        if (desc) {
          html += '<div class="result-desc">' + escapeHtml(desc) + '</div>';
        }
        if (linkUrl) {
          html += '<div class="result-link"><a href="' + escapeHtml(linkUrl) + '" target="_blank" rel="noopener">Direct IPA Download Link</a></div>';
        }
        resultBox.innerHTML = html;
        resultBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }

      form.addEventListener('submit', function(e) {
        e.preventDefault();
        resultBox.className = 'result-box hidden';
        resultBox.innerHTML = '';

        var file = fileInput.files && fileInput.files[0];
        if (!file) {
          showResult(false, 'Validation Error', 'Please select an .ipa file.');
          return;
        }
        if (!file.name.toLowerCase().endsWith('.ipa')) {
          showResult(false, 'Validation Error', 'Only .ipa files are allowed.');
          return;
        }
        if (file.size <= 0) {
          showResult(false, 'Validation Error', 'Selected file is empty.');
          return;
        }
        if (file.size > 500 * 1024 * 1024) {
          showResult(false, 'Validation Error', 'File size exceeds the 500 MB limit.');
          return;
        }

        var formData = new FormData(form);

        submitBtn.disabled = true;
        submitBtn.textContent = 'Publishing to Store...';
        progressSection.classList.remove('hidden');
        progressBar.style.width = '0%';
        progressStatus.textContent = 'Starting upload (0%)...';

        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/upload', true);

        xhr.upload.onprogress = function(event) {
          if (event.lengthComputable && event.total > 0) {
            var pct = Math.min(100, Math.round((event.loaded / event.total) * 100));
            progressBar.style.width = pct + '%';
            if (pct < 100) {
              progressStatus.textContent = 'Uploading to Worker: ' + pct + '% (' + formatBytes(event.loaded) + ' / ' + formatBytes(event.total) + ')';
            } else {
              progressStatus.textContent = 'Uploading to GitHub & updating store source... please wait.';
            }
          }
        };

        xhr.onload = function() {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Publish to Store';
          try {
            var data = JSON.parse(xhr.responseText);
            if (xhr.status >= 200 && xhr.status < 300 && data.ok) {
              progressBar.style.width = '100%';
              progressStatus.textContent = 'Upload and publish complete!';
              showResult(
                true,
                'Published ' + data.name + ' v' + data.version + ' successfully!',
                data.message || 'Published. CDN updates in ~5 min.',
                data.downloadURL
              );
              fileInput.value = '';
              fileText.textContent = 'Tap or click to select .ipa file';
            } else {
              showResult(false, 'Publish Failed (' + xhr.status + ')', data.error || 'Server error occurred.');
            }
          } catch (err) {
            showResult(false, 'Server Error (' + xhr.status + ')', xhr.responseText || err.message);
          }
        };

        xhr.onerror = function() {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Publish to Store';
          showResult(false, 'Network Error', 'Connection failed or timed out during upload.');
        };

        xhr.send(formData);
      });
    })();
  </script>
</body>
</html>
`;

/**
 * Standard JSON response helper
 */
function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*'
    }
  });
}

/**
 * Decode Base64 string to UTF-8 text (handles GitHub newlines & multibyte chars)
 */
function decodeBase64Utf8(base64Str) {
  const clean = base64Str.replace(/\s+/g, '');
  const binaryStr = atob(clean);
  const bytes = Uint8Array.from(binaryStr, ch => ch.charCodeAt(0));
  return new TextDecoder('utf-8').decode(bytes);
}

/**
 * Encode UTF-8 text to Base64 string (handles multibyte chars)
 */
function encodeBase64Utf8(str) {
  const bytes = new TextEncoder().encode(str);
  let binary = '';
  const len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

/**
 * Handle multipart POST /upload
 */
async function handleUpload(request, env) {
  let formData;
  try {
    formData = await request.formData();
  } catch (err) {
    return jsonResponse({ ok: false, error: 'Invalid multipart form data: ' + err.message }, 400);
  }

  // 1. Check password === env.UPLOAD_PASSWORD
  const password = formData.get('password');
  if (!env.UPLOAD_PASSWORD || password !== env.UPLOAD_PASSWORD) {
    return jsonResponse({ ok: false, error: 'Unauthorized: Invalid upload password.' }, 401);
  }

  // 2. Validate input fields
  const name = (formData.get('name') || '').toString().trim();
  const bundleId = (formData.get('bundleId') || '').toString().trim();
  const version = (formData.get('version') || '').toString().trim();
  const subtitle = (formData.get('subtitle') || '').toString().trim();
  const description = (formData.get('description') || '').toString().trim();
  const category = (formData.get('category') || 'utilities').toString().trim();
  const release = (formData.get('release') || 'latest').toString().trim();
  const ipa = formData.get('ipa');

  if (!name || !bundleId || !version) {
    return jsonResponse({ ok: false, error: 'Missing required field: name, bundleId, and version are required.' }, 400);
  }

  if (release !== 'latest' && release !== 'community') {
    return jsonResponse({ ok: false, error: 'Release must be "latest" or "community".' }, 400);
  }

  if (!ipa || typeof ipa === 'string' || (!ipa.size && typeof ipa.size !== 'number')) {
    return jsonResponse({ ok: false, error: 'Missing or invalid .ipa file.' }, 400);
  }

  const fileSize = ipa.size;
  const MAX_FILE_SIZE = 500 * 1024 * 1024; // 500 MB

  if (fileSize <= 0) {
    return jsonResponse({ ok: false, error: 'File size must be greater than 0.' }, 400);
  }

  if (fileSize > MAX_FILE_SIZE) {
    return jsonResponse({ ok: false, error: 'File size exceeds the 500 MB limit.' }, 400);
  }

  if (!env.GITHUB_TOKEN) {
    return jsonResponse({ ok: false, error: 'Server configuration error: GITHUB_TOKEN is not configured.' }, 500);
  }

  // 3. Upload the IPA to the GitHub release as an asset
  const repo = 'spananide/spanani-store';
  const rawAssetName = `${bundleId}-${version}.ipa`;
  const assetName = rawAssetName.replace(/\s+/g, '_');

  const ghHeaders = {
    'Authorization': `Bearer ${env.GITHUB_TOKEN}`,
    'User-Agent': 'spanani-upload-worker',
    'Accept': 'application/vnd.github+json'
  };

  // 3a. Get release_id
  const releaseUrl = `https://api.github.com/repos/${repo}/releases/tags/${encodeURIComponent(release)}`;
  const releaseRes = await fetch(releaseUrl, { headers: ghHeaders });

  if (!releaseRes.ok) {
    const errText = await releaseRes.text();
    return jsonResponse({
      ok: false,
      error: `GitHub release tag "${release}" not found or inaccessible (${releaseRes.status}): ${errText}`
    }, releaseRes.status === 404 ? 404 : 502);
  }

  const releaseData = await releaseRes.json();
  const releaseId = releaseData.id;

  // 3b. Check if asset already exists on that release, delete old asset first
  let existingAsset = (releaseData.assets || []).find(a => a.name === assetName);

  if (!existingAsset && Array.isArray(releaseData.assets) && releaseData.assets.length >= 30) {
    const assetsRes = await fetch(`https://api.github.com/repos/${repo}/releases/${releaseId}/assets?per_page=100`, {
      headers: ghHeaders
    });
    if (assetsRes.ok) {
      const assetList = await assetsRes.json();
      existingAsset = assetList.find(a => a.name === assetName);
    }
  }

  if (existingAsset) {
    const deleteRes = await fetch(`https://api.github.com/repos/${repo}/releases/assets/${existingAsset.id}`, {
      method: 'DELETE',
      headers: ghHeaders
    });
    if (!deleteRes.ok && deleteRes.status !== 404) {
      const errText = await deleteRes.text();
      return jsonResponse({
        ok: false,
        error: `Failed to delete existing asset "${assetName}" (${deleteRes.status}): ${errText}`
      }, 502);
    }
  }

  // 3c. Upload asset
  const uploadUrl = `https://uploads.github.com/repos/${repo}/releases/${releaseId}/assets?name=${encodeURIComponent(assetName)}`;
  const uploadHeaders = {
    'Authorization': `Bearer ${env.GITHUB_TOKEN}`,
    'User-Agent': 'spanani-upload-worker',
    'Content-Type': 'application/octet-stream',
    'Accept': 'application/vnd.github+json',
    'Content-Length': String(fileSize)
  };

  const uploadRes = await fetch(uploadUrl, {
    method: 'POST',
    headers: uploadHeaders,
    body: typeof ipa.stream === 'function' ? ipa.stream() : ipa,
    duplex: 'half'
  });

  if (!uploadRes.ok) {
    const errText = await uploadRes.text();
    return jsonResponse({
      ok: false,
      error: `GitHub asset upload failed (${uploadRes.status}): ${errText}`
    }, 502);
  }

  const assetUploadData = await uploadRes.json();
  const downloadURL = assetUploadData.browser_download_url ||
    `https://github.com/${repo}/releases/download/${encodeURIComponent(release)}/${encodeURIComponent(assetName)}`;

  // 4. Update source/source.json via GitHub Contents API
  const contentUrl = `https://api.github.com/repos/${repo}/contents/source/source.json?ref=develop`;
  const contentRes = await fetch(contentUrl, { headers: ghHeaders });

  if (!contentRes.ok) {
    const errText = await contentRes.text();
    return jsonResponse({
      ok: false,
      error: `Failed to fetch source/source.json from GitHub (${contentRes.status}): ${errText}`
    }, 502);
  }

  const contentData = await contentRes.json();
  const fileSha = contentData.sha;
  const rawContentBase64 = contentData.content;

  let sourceJsonText;
  try {
    sourceJsonText = decodeBase64Utf8(rawContentBase64);
  } catch (err) {
    return jsonResponse({ ok: false, error: `Failed to decode source.json base64: ${err.message}` }, 500);
  }

  let sourceObj;
  try {
    sourceObj = JSON.parse(sourceJsonText);
  } catch (err) {
    return jsonResponse({ ok: false, error: `Failed to parse source.json: ${err.message}` }, 500);
  }

  if (!Array.isArray(sourceObj.apps)) {
    sourceObj.apps = [];
  }

  const nowIso = new Date().toISOString();
  const newVersionEntry = {
    version,
    date: nowIso,
    localizedDescription: description || subtitle || "Published via spanani Upload.",
    downloadURL,
    size: fileSize
  };

  const existingApp = sourceObj.apps.find(a => a.bundleIdentifier === bundleId);

  if (existingApp) {
    if (!Array.isArray(existingApp.versions)) {
      existingApp.versions = [];
    }
    // Remove existing version entry if re-uploading the same version string to avoid duplicates
    existingApp.versions = existingApp.versions.filter(v => v.version !== version);
    existingApp.versions.unshift(newVersionEntry);
    existingApp.version = version;
    existingApp.date = nowIso;
    existingApp.downloadURL = downloadURL;
    existingApp.size = fileSize;
    if (name) existingApp.name = name;
    if (subtitle) existingApp.subtitle = subtitle;
    if (description) existingApp.localizedDescription = description;
    if (category) existingApp.category = category;
  } else {
    const newAppEntry = {
      name,
      bundleIdentifier: bundleId,
      developerName: "spanani.de",
      subtitle: subtitle || "",
      localizedDescription: description || "",
      iconURL: "",
      tintColor: "9955E7",
      category,
      version,
      date: nowIso,
      downloadURL,
      size: fileSize,
      versions: [newVersionEntry],
      appPermissions: {
        entitlements: [],
        privacy: {}
      }
    };
    sourceObj.apps.push(newAppEntry);
  }

  const updatedJsonStr = JSON.stringify(sourceObj, null, 2) + '\n';
  const updatedBase64 = encodeBase64Utf8(updatedJsonStr);

  const putPayload = {
    message: `App: ${name} ${version}`,
    content: updatedBase64,
    sha: fileSha,
    branch: "develop",
    committer: {
      name: "spananide",
      email: "mattisonnenschein@icloud.com"
    }
  };

  const putRes = await fetch(`https://api.github.com/repos/${repo}/contents/source/source.json`, {
    method: 'PUT',
    headers: {
      ...ghHeaders,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(putPayload)
  });

  if (!putRes.ok) {
    const errText = await putRes.text();
    return jsonResponse({
      ok: false,
      error: `Failed to update source/source.json on GitHub (${putRes.status}): ${errText}`
    }, 502);
  }

  // 5. Return JSON success
  return jsonResponse({
    ok: true,
    name,
    version,
    downloadURL,
    message: "Published. CDN updates in ~5 min."
  }, 200);
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Max-Age': '86400'
        }
      });
    }

    // GET / -> Serve HTML page
    if (request.method === 'GET' && (url.pathname === '/' || url.pathname === '/index.html')) {
      return new Response(HTML_PAGE, {
        status: 200,
        headers: {
          'Content-Type': 'text/html; charset=utf-8',
          'Cache-Control': 'no-cache, no-store, must-revalidate'
        }
      });
    }

    // POST /upload -> Handle upload and publish
    if (request.method === 'POST' && url.pathname === '/upload') {
      try {
        return await handleUpload(request, env);
      } catch (err) {
        return jsonResponse({
          ok: false,
          error: err.message || 'Unexpected server error during upload.'
        }, 500);
      }
    }

    return jsonResponse({ ok: false, error: 'Not found' }, 404);
  }
};
