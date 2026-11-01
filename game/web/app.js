/* Grand Strategy-1914 — interface cliente (vanilla JS, sans dependance). */

const app = {
  view: null,
  selectedProvince: null,
  selectedArmy: null,
  activeTab: "orders",
  orders: emptyOrders(),
  busy: false,
  victoryKey: null,
};

const HEX = { w: 22.5, h: 26, vert: 19.5, ox: 12, oy: 14 };
const SVG_NS = "http://www.w3.org/2000/svg";

function emptyOrders() {
  return { moves: [], research: null, construction: [], recruits: [], diplomacy: [], event_choices: {} };
}

function $(selector) { return document.querySelector(selector); }

function esc(value) {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[char]));
}

function fmt(value, digits = 0) {
  const number = Number(value ?? 0);
  return number.toLocaleString("fr-FR", { minimumFractionDigits: digits, maximumFractionDigits: digits });
}

function signed(value, digits = 1) {
  const number = Number(value ?? 0);
  const text = fmt(Math.abs(number), digits);
  return `${number >= 0 ? "+" : "-"}${text}`;
}

async function api(url, payload) {
  const options = payload === undefined
    ? {}
    : { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) };
  const response = await fetch(url, options);
  let data;
  try { data = await response.json(); } catch (_error) { data = { ok: false, error: "Reponse invalide du serveur." }; }
  if (!response.ok) {
    data.ok = false;
    data.error = data.error || `Erreur HTTP ${response.status}`;
  }
  return data;
}

/* ------------------------------------------------------------------ */
/* Demarrage                                                           */
/* ------------------------------------------------------------------ */

async function init() {
  document.addEventListener("click", onDocumentClick);
  document.addEventListener("change", onDocumentChange);
  document.addEventListener("keydown", (event) => { if (event.key === "Escape") closeModal(); });
  $("#modal-backdrop").addEventListener("click", (event) => {
    if (event.target === $("#modal-backdrop")) closeModal();
  });

  const data = await api("/api/view");
  if (data.game) {
    showGame(data);
    return;
  }
  if (data.game === false && Array.isArray(data.playable)) {
    renderSelection(data);
    return;
  }
  showMessage("Serveur indisponible", data.error || "Impossible de charger l'etat du jeu.");
}

function renderSelection(data) {
  $("#selection-screen").classList.remove("hidden");
  $("#game-screen").classList.add("hidden");
  const cards = (data.playable || []).map((nation) => {
    const stats = nation.stats || {};
    return `
      <button class="nation-card" style="--card-color:${esc(nation.color)}" data-action="start-game" data-nation="${esc(nation.id)}">
        <h2>${esc(nation.name)}</h2>
        <div class="nation-sub">${esc(nation.short)} · ${fmt(nation.population, 1)} M hab.</div>
        <div class="ambition">« ${esc((nation.ambitions || [])[0] || "")} »</div>
        <div class="stat-grid">
          <span>Armee <b>${stats.army ?? "-"}</b></span>
          <span>Economie <b>${stats.economy ?? "-"}</b></span>
          <span>Industrie <b>${stats.industry ?? "-"}</b></span>
          <span>Technologie <b>${stats.technology ?? "-"}</b></span>
          <span>Marine <b>${stats.navy ?? "-"}</b></span>
          <span>Cohesion <b>${stats.unity ?? "-"}</b></span>
        </div>
      </button>`;
  }).join("");
  $("#nation-cards").innerHTML = cards || `<div class="empty-state">Aucune nation jouable n'est disponible.</div>`;
}

function showGame(view) {
  app.view = view;
  $("#selection-screen").classList.add("hidden");
  $("#game-screen").classList.remove("hidden");
  renderTopbar();
  renderMap();
  renderProvincePanel();
  renderTab();
  if (view.victory) {
    const key = `${view.victory.type}:${view.victory.nation}:${view.victory.turn}`;
    if (app.victoryKey !== key) {
      app.victoryKey = key;
      showVictoryModal(view.victory);
    }
  }
}

/* ------------------------------------------------------------------ */
/* Barre superieure                                                    */
/* ------------------------------------------------------------------ */

function renderTopbar() {
  const view = app.view;
  const own = view.own;
  $("#player-label").textContent = own ? `${own.name} · joueur` : "Observateur";
  $("#date-label").textContent = view.date;
  $("#turn-label").textContent = `Tour ${view.turn + 1}`;

  const strip = $("#resource-strip");
  if (own) {
    const resource = (label, value, delta) => `
      <div class="resource"><span>${label}</span><b>${fmt(value, 1)}</b>${delta === undefined ? "" : `<span class="delta ${delta >= 0 ? "positive" : "negative"}">${signed(delta)}/mois</span>`}</div>`;
    strip.innerHTML = [
      resource("Vivres", own.stock.food, own.net.food),
      resource("Matieres", own.stock.raw, own.net.raw),
      resource("Richesse", own.stock.wealth, own.net.wealth),
      resource("Main-d'oeuvre", own.manpower),
      resource("Stabilite", own.stability),
      resource("Prestige", own.prestige),
    ].join("");
  } else {
    const provinces = (view.map.provinces || []).length;
    const armies = (view.armies || []).length;
    const wars = (view.wars || []).length;
    strip.innerHTML = `
      <div class="resource"><span>Provinces</span><b>${provinces}</b></div>
      <div class="resource"><span>Armees visibles</span><b>${armies}</b></div>
      <div class="resource"><span>Guerres</span><b>${wars}</b></div>
      <div class="resource"><span>Mode</span><b>Observation</b></div>`;
  }

  const endButton = $("#end-turn-button");
  endButton.disabled = app.busy || Boolean(view.victory);
  endButton.textContent = view.victory ? "Partie terminee" : "Fin du tour";
}

/* ------------------------------------------------------------------ */
/* Carte                                                               */
/* ------------------------------------------------------------------ */

function hexCenter(q, r) {
  return {
    x: HEX.ox + q * HEX.w + (r % 2) * HEX.w / 2 + HEX.w / 2,
    y: HEX.oy + r * HEX.vert + HEX.h / 2,
  };
}

function hexPoints(cx, cy) {
  const w = HEX.w;
  const h = HEX.h;
  return [
    `${cx},${cy - h / 2}`,
    `${cx + w / 2},${cy - h / 4}`,
    `${cx + w / 2},${cy + h / 4}`,
    `${cx},${cy + h / 2}`,
    `${cx - w / 2},${cy + h / 4}`,
    `${cx - w / 2},${cy - h / 4}`,
  ].join(" ");
}

function makeSvg(tag, attributes = {}) {
  const element = document.createElementNS(SVG_NS, tag);
  for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value);
  return element;
}

function nationMap() {
  const map = {};
  for (const nation of app.view.nations || []) map[nation.id] = nation;
  return map;
}

function provinceMap() {
  const map = {};
  for (const province of app.view.map.provinces || []) map[province.id] = province;
  return map;
}

function provinceCentroid(province) {
  const points = province.hexes.map(([q, r]) => hexCenter(q, r));
  const x = points.reduce((sum, point) => sum + point.x, 0) / points.length;
  const y = points.reduce((sum, point) => sum + point.y, 0) / points.length;
  return { x, y };
}

function selectedArmyData() {
  if (!app.selectedArmy || !app.view.own) return null;
  return (app.view.own.armies || []).find((army) => army.id === app.selectedArmy) || null;
}

function renderMap() {
  const svg = $("#map");
  svg.innerHTML = "";
  svg.setAttribute("viewBox", "0 0 900 570");
  const nations = nationMap();
  const provinces = app.view.map.provinces || [];
  const observer = app.view.observer;
  const army = selectedArmyData();
  const moveTargets = new Set();
  if (army) {
    for (const move of army.valid_moves || []) if (move.allowed) moveTargets.add(move.id);
  }

  const hexLayer = makeSvg("g");
  const labelLayer = makeSvg("g");
  const armyLayer = makeSvg("g");

  for (const province of provinces) {
    const controller = nations[province.controller] || { color: "#55606b" };
    const owner = nations[province.owner] || controller;
    const visible = observer || province.visible;
    for (const [q, r] of province.hexes) {
      const center = hexCenter(q, r);
      const polygon = makeSvg("polygon", {
        points: hexPoints(center.x, center.y),
        fill: visible ? controller.color : "#1a2430",
        "fill-opacity": visible ? "0.88" : "0.85",
        stroke: "#0a0f15",
        "stroke-width": "0.4",
        "data-province": province.id,
        class: "hex",
      });
      if (province.id === app.selectedProvince) {
        polygon.setAttribute("stroke", "#e2c68c");
        polygon.setAttribute("stroke-width", "2");
        polygon.setAttribute("fill-opacity", "1");
      } else if (moveTargets.has(province.id)) {
        polygon.setAttribute("stroke", "#e2c68c");
        polygon.setAttribute("stroke-width", "1.3");
        polygon.setAttribute("stroke-dasharray", "3 2");
      } else if (province.controller !== province.owner) {
        polygon.setAttribute("stroke", owner.color || "#d9cba8");
        polygon.setAttribute("stroke-width", "1.15");
      }
      const title = makeSvg("title");
      title.textContent = `${province.name} — ${owner.short || province.owner}${province.controller !== province.owner ? ` (occupee par ${controller.short || province.controller})` : ""}`;
      polygon.appendChild(title);
      hexLayer.appendChild(polygon);
    }
  }

  for (const province of provinces) {
    const visible = observer || province.visible;
    if (!visible) continue;
    if (province.strategic < 4 && province.city !== province.name) continue;
    const center = provinceCentroid(province);
    const label = makeSvg("text", {
      x: center.x,
      y: center.y,
      "text-anchor": "middle",
      "dominant-baseline": "middle",
      "font-size": province.strategic >= 5 ? "4.8" : "4.1",
      fill: "#f2ead9",
      stroke: "#0a0f15",
      "stroke-width": "1.1",
      "paint-order": "stroke",
      "pointer-events": "none",
      "font-family": "Georgia, serif",
    });
    label.textContent = province.city;
    labelLayer.appendChild(label);
  }

  const grouped = {};
  for (const entry of app.view.armies || []) {
    if (!grouped[entry.province]) grouped[entry.province] = [];
    grouped[entry.province].push(entry);
  }
  for (const [provinceId, entries] of Object.entries(grouped)) {
    const province = provinces.find((item) => item.id === provinceId);
    if (!province) continue;
    const center = provinceCentroid(province);
    const first = entries[0];
    const nation = nations[first.nation] || { color: "#777" };
    const total = entries.reduce((sum, entry) => sum + (entry.regiments ?? entry.regiments_estimate ?? 0), 0);
    const group = makeSvg("g", { "data-province": provinceId, class: "army-marker", cursor: "pointer" });
    group.appendChild(makeSvg("circle", {
      cx: center.x,
      cy: center.y - 4,
      r: entries.length > 1 ? 7.4 : 6.4,
      fill: nation.color,
      stroke: "#f4ead7",
      "stroke-width": "0.9",
    }));
    const text = makeSvg("text", {
      x: center.x,
      y: center.y - 4,
      "text-anchor": "middle",
      "dominant-baseline": "middle",
      "font-size": "4.6",
      "font-weight": "bold",
      fill: "#10151c",
      "pointer-events": "none",
      "font-family": "Segoe UI, sans-serif",
    });
    text.textContent = total > 99 ? "99+" : String(total);
    group.appendChild(text);
    if (entries.length > 1) {
      const badge = makeSvg("text", {
        x: center.x + 6,
        y: center.y + 2,
        "text-anchor": "middle",
        "font-size": "4",
        fill: "#f4ead7",
        "pointer-events": "none",
      });
      badge.textContent = `x${entries.length}`;
      group.appendChild(badge);
    }
    armyLayer.appendChild(group);
  }

  svg.appendChild(hexLayer);
  svg.appendChild(labelLayer);
  svg.appendChild(armyLayer);
  svg.onclick = onMapClick;
}

function onMapClick(event) {
  const target = event.target.closest("[data-province]");
  if (!target) return;
  const provinceId = target.getAttribute("data-province");
  const army = selectedArmyData();
  if (army) {
    const move = (army.valid_moves || []).find((item) => item.id === provinceId && item.allowed);
    if (move) {
      queueMove(army.id, provinceId);
      return;
    }
  }
  selectProvince(provinceId);
}

function selectProvince(provinceId) {
  app.selectedProvince = provinceId;
  const ownArmies = (app.view.own?.armies || []).filter((army) => army.province === provinceId);
  app.selectedArmy = ownArmies.length ? ownArmies[0].id : null;
  renderMap();
  renderProvincePanel();
  if (app.activeTab === "orders") renderTab();
}

/* ------------------------------------------------------------------ */
/* Panneau province                                                    */
/* ------------------------------------------------------------------ */

function renderProvincePanel() {
  const panel = $("#province-panel");
  const province = (app.view.map.provinces || []).find((item) => item.id === app.selectedProvince);
  if (!province) {
    panel.innerHTML = `<p class="muted">Selectionnez une province sur la carte.</p>`;
    return;
  }
  const nations = nationMap();
  const owner = nations[province.owner] || { short: province.owner };
  const controller = nations[province.controller] || { short: province.controller };
  const armies = (app.view.armies || []).filter((army) => army.province === province.id);
  const own = app.view.own;
  const ownArmies = (own?.armies || []).filter((army) => army.province === province.id);

  const armyLines = armies.length
    ? armies.map((army) => {
      const nation = nations[army.nation] || { short: army.nation, color: "#888" };
      const strength = army.exact
        ? `${army.infantry} inf. · ${army.artillery} art. · ${army.cavalry} cav.`
        : `~${army.regiments_estimate} regiments (estimation)`;
      return `<div class="army-card"><div class="army-head"><strong style="color:${esc(nation.color)}">${esc(nation.short)} — ${esc(army.name)}</strong><span>Rav. ${fmt(army.supply)} · Moral ${fmt(army.morale)}</span></div><div class="army-stats">${esc(strength)}</div></div>`;
    }).join("")
    : `<p class="muted small">Aucune armee visible dans cette province.</p>`;

  const moveButtons = ownArmies.map((army) => {
    const selected = app.selectedArmy === army.id;
    return `<button class="small-button" data-action="${selected ? "deselect-army" : "select-army"}" data-army="${esc(army.id)}">${selected ? "Deselectionner" : "Choisir pour deplacer"}</button>`;
  }).join(" ");

  panel.innerHTML = `
    <h3>${esc(province.name)} <span class="muted" style="font-size:12px">· ${esc(province.city)}</span></h3>
    <div class="province-meta">
      Proprietaire : <b>${esc(owner.short)}</b> · Controle : <b>${esc(controller.short)}</b>
      ${province.controller !== province.owner ? `<span class="tag war">occupee</span>` : ""}
      ${province.visible || app.view.observer ? "" : `<span class="tag">hors vue</span>`}
    </div>
    <div class="province-grid">
      <span>Terrain <b>${esc(province.terrain)}</b></span>
      <span>Industrie <b>${province.industry}</b></span>
      <span>Fortification <b>${province.fortification}</b></span>
      <span>Valeur strategique <b>${province.strategic}</b></span>
      <span>Vivres <b>${province.resource.food}</b></span>
      <span>Matieres <b>${province.resource.raw}</b></span>
      <span>Richesse <b>${province.resource.wealth}</b></span>
      <span>Port <b>${province.port ? "oui" : "non"}</b></span>
    </div>
    <h4 style="margin-top:12px">Armees</h4>
    ${armyLines}
    ${moveButtons ? `<div style="margin-top:8px">${moveButtons}</div>` : ""}
    ${app.selectedArmy ? `<p class="small muted" style="margin-top:8px">Cliquez une province voisine en surbrillance pour deplacer l'armee selectionnee.</p>` : ""}`;
}

/* ------------------------------------------------------------------ */
/* Onglets                                                             */
/* ------------------------------------------------------------------ */

function renderTab() {
  document.querySelectorAll("#tabs .tab").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === app.activeTab);
  });
  const content = $("#tab-content");
  if (!app.view.own) {
    content.innerHTML = renderObserverTab();
    return;
  }
  const renderers = {
    orders: renderOrdersTab,
    diplomacy: renderDiplomacyTab,
    economy: renderEconomyTab,
    research: renderResearchTab,
    world: renderWorldTab,
    report: renderReportTab,
    log: renderLogTab,
  };
  content.innerHTML = (renderers[app.activeTab] || renderOrdersTab)();
}

function renderObserverTab() {
  return `
    <h3>Mode observation</h3>
    <p>Vous suivez la partie sans diriger de pays. Les sept puissances jouables restent disponibles : vous pouvez prendre le controle d'une nation encore en vie.</p>
    <h4>Prendre le controle</h4>
    <div class="form-row">
      <select id="take-control-nation">
        ${(app.view.nations || []).filter((nation) => nation.playable && !nation.eliminated).map((nation) => `<option value="${esc(nation.id)}">${esc(nation.name)}</option>`).join("")}
      </select>
      <button class="primary-button" data-action="take-control">Diriger</button>
    </div>
    <p class="small muted">Le changement est immediat et conserve l'etat du monde.</p>
    ${renderWorldTab()}`;
}

function renderOrdersTab() {
  const own = app.view.own;
  const pendingEvents = app.view.pending_events || [];
  const eventCards = pendingEvents.map((event) => {
    const chosen = app.orders.event_choices[event.id] || event.default_option;
    const options = (event.options || []).map((option) => `
      <label class="event-option">
        <input type="radio" name="event-${esc(event.id)}" value="${esc(option.id)}"
          data-event-option data-event-id="${esc(event.id)}" data-option-id="${esc(option.id)}"
          ${chosen === option.id ? "checked" : ""}>
        <strong>${esc(option.label)}</strong>
        <small>${esc(option.description || "")}</small>
      </label>`).join("");
    return `<div class="event-card"><h4>${esc(event.title)}</h4><p>${esc(event.text)}</p>${options}<p class="small muted">Sans choix, l'option par defaut s'appliquera apres deux tours.</p></div>`;
  }).join("");

  const armyCards = (own.armies || []).map((army) => {
    const move = app.orders.moves.find((item) => item.army === army.id);
    const province = (app.view.map.provinces || []).find((item) => item.id === army.province);
    return `
      <div class="army-card ${app.selectedArmy === army.id ? "selected" : ""}">
        <div class="army-head"><strong>${esc(army.name)}</strong><span>${esc(province?.name || army.province)}</span></div>
        <div class="army-stats">
          ${army.infantry} inf. · ${army.artillery} art. · ${army.cavalry} cav. — ${army.regiments} regiments<br>
          Ravitaillement ${fmt(army.supply)} · Moral ${fmt(army.morale)} · Retranchement ${fmt(army.entrenchment, 1)}
        </div>
        <button class="small-button" data-action="${app.selectedArmy === army.id ? "deselect-army" : "select-army"}" data-army="${esc(army.id)}">${app.selectedArmy === army.id ? "Deselectionner" : "Choisir et deplacer"}</button>
        ${move ? `<div class="small muted" style="margin-top:6px">Ordre : vers ${esc(move.label)} <button class="danger-button" data-action="remove-move" data-index="${app.orders.moves.indexOf(move)}">Annuler</button></div>` : ""}
      </div>`;
  }).join("");

  const pendingRows = [];
  app.orders.moves.forEach((move, index) => pendingRows.push(`<li><span>Deplacement : ${esc(move.label)}</span><button class="danger-button" data-action="remove-move" data-index="${index}">Retirer</button></li>`));
  if (app.orders.research) pendingRows.push(`<li><span>Recherche : ${esc(app.orders.research)}</span><button class="danger-button" data-action="remove-research">Retirer</button></li>`);
  app.orders.construction.forEach((item, index) => pendingRows.push(`<li><span>Construction : ${esc(item.kind)} a ${esc(item.provinceName)}</span><button class="danger-button" data-action="remove-construction" data-index="${index}">Retirer</button></li>`));
  app.orders.recruits.forEach((item, index) => pendingRows.push(`<li><span>Recrutement : ${item.count} ${esc(item.unit)} a ${esc(item.provinceName)}</span><button class="danger-button" data-action="remove-recruit" data-index="${index}">Retirer</button></li>`));
  app.orders.diplomacy.forEach((item, index) => pendingRows.push(`<li><span>Diplomatie : ${esc(item.label)}</span><button class="danger-button" data-action="remove-diplomacy" data-index="${index}">Retirer</button></li>`));

  return `
    <h3>Ordres du mois</h3>
    <p class="small">Les ordres sont resolus simultanement avec ceux des autres nations. Une armee non deplacee tient sa position et se retranche.</p>
    ${eventCards}
    <h4>Armees</h4>
    ${armyCards || `<div class="empty-state">Aucune armee disponible.</div>`}
    <h4>Ordres en attente</h4>
    ${pendingRows.length ? `<ul class="pending-list">${pendingRows.join("")}</ul>` : `<div class="empty-state">Aucun ordre en attente. Vous pouvez terminer le tour.</div>`}
    <p class="small muted">Astuce : selectionnez une armee, puis cliquez une province voisine sur la carte. Les provinces accessibles sont entourees en pointille dore.</p>`;
}

function renderDiplomacyTab() {
  const own = app.view.own;
  const config = app.view.config.diplomacy;
  const actions = {};
  for (const entry of own.diplomacy || []) actions[entry.target] = entry;
  const rows = (app.view.nations || []).filter((nation) => nation.id !== own.id).map((nation) => {
    const entry = actions[nation.id] || {};
    const relation = entry.relation ?? nation.relation;
    const category = entry.category || nation.relation_category;
    const tags = [
      nation.at_war ? `<span class="tag war">guerre</span>` : "",
      nation.ally ? `<span class="tag ally">alliance</span>` : "",
      nation.eliminated ? `<span class="tag">eliminee</span>` : "",
    ].join("");
    const buttons = [];
    if (!nation.eliminated) {
      if (entry.at_war) {
        buttons.push(`<button class="small-button" data-action="diplomacy" data-kind="peace" data-target="${esc(nation.id)}">Proposer la paix</button>`);
      } else {
        buttons.push(`<button class="small-button" data-action="diplomacy" data-kind="improve" data-target="${esc(nation.id)}">Ameliorer (${config.improve_cost})</button>`);
        if (entry.can_alliance) buttons.push(`<button class="small-button" data-action="diplomacy" data-kind="alliance" data-target="${esc(nation.id)}">Alliance (${config.alliance_cost})</button>`);
        if (entry.can_nap) buttons.push(`<button class="small-button" data-action="diplomacy" data-kind="nap" data-target="${esc(nation.id)}">Non-agression (${config.nap_cost})</button>`);
        if (entry.can_trade) buttons.push(`<button class="small-button" data-action="diplomacy" data-kind="trade" data-target="${esc(nation.id)}">Commerce (${config.trade_cost})</button>`);
        if (entry.can_transit) buttons.push(`<button class="small-button" data-action="diplomacy" data-kind="transit" data-target="${esc(nation.id)}">Transit (${config.transit_cost})</button>`);
        buttons.push(`<button class="danger-button" data-action="diplomacy" data-kind="war" data-target="${esc(nation.id)}">Declarer la guerre</button>`);
      }
    }
    return `<tr>
      <td><strong>${esc(nation.short)}</strong> ${tags}<br><span class="small muted">${esc(nation.name)}</span></td>
      <td><span class="relation-badge ${esc(category)}">${fmt(relation)}</span></td>
      <td>${nation.provinces} prov.<br><span class="small muted">${nation.armies} armees</span></td>
      <td><div class="actions">${buttons.join(" ")}</div></td>
    </tr>`;
  }).join("");

  const pending = app.orders.diplomacy.length
    ? `<ul class="pending-list">${app.orders.diplomacy.map((item, index) => `<li><span>${esc(item.label)}</span><button class="danger-button" data-action="remove-diplomacy" data-index="${index}">Retirer</button></li>`).join("")}</ul>`
    : `<div class="empty-state">Aucune action diplomatique en attente.</div>`;

  return `
    <h3>Diplomatie</h3>
    <p class="small">Relations de -100 (hostilite) a +100 (amitie). Les traités sont rompus par une declaration de guerre. Une paix transfere les provinces occupees (H-010).</p>
    <h4>Actions en attente</h4>
    ${pending}
    <h4>Puissances</h4>
    <table class="data-table">
      <thead><tr><th>Nation</th><th>Relation</th><th>Force</th><th>Actions</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
    <p class="small muted">Les propositions peuvent etre refusees : le cout est engage meme en cas de refus.</p>`;
}

function renderEconomyTab() {
  const own = app.view.own;
  const controlled = (app.view.map.provinces || []).filter((province) => province.controller === own.id);
  const provinceOptions = controlled.map((province) => `<option value="${esc(province.id)}">${esc(province.name)} (ind. ${province.industry}, fort. ${province.fortification})</option>`).join("");
  const prod = own.production || {};
  const cons = own.consumption || {};
  const net = own.net || {};
  const rows = ["food", "raw", "wealth"].map((key) => {
    const label = { food: "Vivres", raw: "Matieres premieres", wealth: "Richesse" }[key];
    return `<tr><td>${label}</td><td>${fmt(prod[key], 1)}</td><td>${fmt(cons[key], 1)}</td><td>${signed(net[key], 1)}</td></tr>`;
  }).join("");

  const constructionQueue = (own.construction || []).length
    ? `<ul class="pending-list">${own.construction.map((item, index) => `<li><span>${esc(item.kind)} a ${esc(item.province)} — ${item.turns_left} tour(s)</span><button class="danger-button" data-action="remove-construction" data-index="${index}">Annuler</button></li>`).join("")}</ul>`
    : `<div class="empty-state">Aucune construction en cours.</div>`;
  const recruitQueue = (own.recruits || []).length
    ? `<ul class="pending-list">${own.recruits.map((item, index) => `<li><span>${item.count} ${esc(item.unit)} a ${esc(item.province)} — ${item.turns_left} tour(s)</span><button class="danger-button" data-action="remove-recruit" data-index="${index}">Annuler</button></li>`).join("")}</ul>`
    : `<div class="empty-state">Aucun recrutement en cours.</div>`;

  return `
    <h3>Economie</h3>
    <table class="data-table">
      <thead><tr><th>Ressource</th><th>Production</th><th>Consommation</th><th>Solde</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
    <p class="small muted">Stocks : ${fmt(own.stock.food, 1)} vivres · ${fmt(own.stock.raw, 1)} matieres · ${fmt(own.stock.wealth, 1)} richesse · ${fmt(own.manpower, 0)} main-d'oeuvre.</p>

    <h4>Construction</h4>
    <div class="form-row">
      <select id="construction-province">${provinceOptions}</select>
      <select id="construction-kind">
        <option value="industry">Industrie (+1)</option>
        <option value="fortification">Fortification (+1)</option>
      </select>
      <button class="primary-button" data-action="queue-construction">Planifier</button>
    </div>
    <p class="cost-line">Industrie : 25 richesse + 20 matieres. Fortification : 20 richesse + 15 matieres. Deux tours.</p>
    ${constructionQueue}

    <h4>Recrutement</h4>
    <div class="form-row">
      <select id="recruit-province">${provinceOptions}</select>
      <select id="recruit-unit">
        <option value="infantry">Infanterie</option>
        <option value="artillery">Artillerie</option>
        <option value="cavalry">Cavalerie</option>
      </select>
      <input id="recruit-count" type="number" min="1" max="6" value="1">
      <button class="primary-button" data-action="queue-recruit">Recruter</button>
    </div>
    <p class="cost-line">Infanterie : 4 richesse, 3 vivres, 20 main-d'oeuvre. Artillerie : 7 richesse, 5 matieres, 10 main-d'oeuvre. Cavalerie : 6 richesse, 2 vivres, 15 main-d'oeuvre. Un tour.</p>
    ${recruitQueue}`;
}

function renderResearchTab() {
  const own = app.view.own;
  const progress = own.research_cost ? Math.min(100, (own.research_progress / own.research_cost) * 100) : 0;
  const current = own.research_tech
    ? `<div class="tech-card current">
         <div class="tech-top"><strong>${esc(own.research_name || own.research_tech)}</strong><span>${fmt(own.research_progress, 1)} / ${fmt(own.research_cost, 0)}</span></div>
         <div class="progress-track"><div class="progress-fill" style="width:${progress}%"></div></div>
         <div class="tech-meta">${fmt(own.research_points, 1)} points de recherche par mois.</div>
       </div>`
    : `<div class="empty-state">Aucune recherche en cours. Choisissez une technologie disponible.</div>`;

  const available = (own.available_techs || []).map((tech) => {
    const classes = ["tech-card"];
    if (tech.available) classes.push("available");
    else classes.push("locked");
    if (tech.current || app.orders.research === tech.id) classes.push("current");
    const action = tech.available ? `data-action="queue-research" data-tech="${esc(tech.id)}"` : "";
    return `<div class="${classes.join(" ")}" ${action}>
      <div class="tech-top"><strong>${esc(tech.name)}</strong><span>${tech.cost} pts · ${tech.year}</span></div>
      <div class="tech-meta">${esc(tech.branch)}${tech.requires.length ? ` · requiert ${esc(tech.requires.join(", "))}` : ""}</div>
      <div class="tech-desc">${esc(tech.description)}</div>
      ${tech.available ? `<div class="tech-meta">${tech.current ? "Recherche en cours" : app.orders.research === tech.id ? "Planifiee pour ce tour" : "Cliquer pour planifier"}</div>` : `<div class="tech-meta">Indisponible (date ou prerequis).</div>`}
    </div>`;
  }).join("");

  const known = (own.known_techs || []).map((tech) => `<span class="tag">${esc(tech.name)}</span>`).join(" ");
  return `
    <h3>Recherche</h3>
    <p class="small">Cinq branches, vingt technologies de 1914 a 1945. Rechercher trop en avance coute plus cher.</p>
    <h4>Recherche en cours</h4>
    ${current}
    <h4>Technologies disponibles</h4>
    ${available || `<div class="empty-state">Aucune technologie recherchable pour le moment.</div>`}
    <h4>Technologies maitrisees</h4>
    <p>${known || `<span class="muted small">Aucune.</span>`}</p>`;
}

function renderWorldTab() {
  const nations = app.view.nations || [];
  const byId = nationMap();
  const own = app.view.own;
  const rows = nations.map((nation) => `
    <tr>
      <td><strong style="color:${esc(nation.color)}">${esc(nation.short)}</strong>${nation.is_player ? `<span class="tag">vous</span>` : ""}${nation.eliminated ? `<span class="tag">eliminee</span>` : ""}<br><span class="small muted">${esc(nation.name)}</span></td>
      <td>${own && nation.id !== own.id ? `<span class="relation-badge ${esc(nation.relation_category)}">${fmt(nation.relation)}</span>` : "—"}</td>
      <td>${fmt(nation.stability, 0)}</td>
      <td>${nation.provinces}</td>
      <td>${nation.armies}</td>
      <td>${fmt(nation.prestige, 0)}</td>
      <td>${nation.at_war ? `<span class="tag war">guerre</span>` : nation.ally ? `<span class="tag ally">alliee</span>` : `<span class="muted small">—</span>`}</td>
    </tr>`).join("");

  const wars = (app.view.wars || []).map(([a, b]) => `<li>${esc(byId[a]?.short || a)} contre ${esc(byId[b]?.short || b)}</li>`).join("");
  const alliances = (app.view.alliances || []).map(([a, b]) => `<li>${esc(byId[a]?.short || a)} — ${esc(byId[b]?.short || b)}</li>`).join("");

  return `
    <h3>Etat du monde</h3>
    <table class="data-table">
      <thead><tr><th>Nation</th><th>Relation</th><th>Stab.</th><th>Prov.</th><th>Armees</th><th>Prest.</th><th>Statut</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
    <h4>Guerres en cours</h4>
    ${wars ? `<ul class="pending-list">${wars}</ul>` : `<div class="empty-state">Aucune guerre en cours.</div>`}
    <h4>Alliances</h4>
    ${alliances ? `<ul class="pending-list">${alliances}</ul>` : `<div class="empty-state">Aucune alliance active.</div>`}`;
}

function renderReportTab() {
  const report = app.view.report || [];
  const victory = app.view.victory;
  const progress = app.view.victory_progress;
  const victoryBox = victory
    ? `<div class="victory-box"><h3>${esc(victory.message)}</h3><p>${victory.player_won ? "Victoire de votre nation." : "La partie est terminee."}</p></div>`
    : "";
  const progressBox = progress ? `
    <h4>Conditions de victoire</h4>
    <p class="small">Territoriale : ${fmt(progress.territorial * 100, 1)} % des provinces (seuil ${fmt(app.view.config.victory.territorial_share * 100, 0)} %).</p>
    <div class="progress-track"><div class="progress-fill" style="width:${Math.min(100, progress.territorial * 100)}%"></div></div>
    <p class="small" style="margin-top:8px">Coalition : ${fmt(progress.coalition * 100, 1)} % (seuil ${fmt(app.view.config.victory.diplomatic_share * 100, 0)} %).</p>
    <div class="progress-track"><div class="progress-fill" style="width:${Math.min(100, progress.coalition * 100)}%"></div></div>
    <p class="small" style="margin-top:8px">Indice economique : ${fmt(progress.economic_index, 3)} · serie de leadership : ${progress.economic_streak}/${app.view.config.victory.economic_turns} tours.</p>` : "";
  const entries = report.length
    ? report.map((entry) => `<div class="report-entry ${esc(entry.category)}">${esc(entry.message)}</div>`).join("")
    : `<div class="empty-state">Aucun rapport pour le moment. Terminez un tour.</div>`;
  return `<h3>Rapport</h3>${victoryBox}${progressBox}<h4>Dernier tour</h4>${entries}`;
}

function renderLogTab() {
  const entries = (app.view.log || []).slice().reverse();
  const html = entries.map((entry) => `<div class="log-entry ${esc(entry.category)}"><strong>${esc(entry.date)}</strong> — ${esc(entry.message)}</div>`).join("");
  return `<h3>Journal</h3>${html || `<div class="empty-state">Le journal est vide.</div>`}`;
}

/* ------------------------------------------------------------------ */
/* Interactions                                                        */
/* ------------------------------------------------------------------ */

async function onDocumentClick(event) {
  const mapTarget = event.target.closest("#map [data-province]");
  if (mapTarget) {
    onMapClick({ target: mapTarget });
    return;
  }
  const element = event.target.closest("[data-action]");
  if (!element) return;
  const action = element.dataset.action;
  switch (action) {
    case "start-game":
      await startGame(element.dataset.nation);
      break;
    case "observer":
      await startGame(null);
      break;
    case "open-load":
      await showLoadModal();
      break;
    case "save":
      showSaveModal();
      break;
    case "end-turn":
      await endTurn();
      break;
    case "tab":
      app.activeTab = element.dataset.tab;
      renderTab();
      break;
    case "select-army": {
      const army = (app.view.own?.armies || []).find((item) => item.id === element.dataset.army);
      if (army) {
        app.selectedArmy = army.id;
        app.selectedProvince = army.province;
        app.activeTab = "orders";
        renderMap();
        renderProvincePanel();
        renderTab();
      }
      break;
    }
    case "deselect-army":
      app.selectedArmy = null;
      renderMap();
      renderProvincePanel();
      renderTab();
      break;
    case "remove-move":
      app.orders.moves.splice(Number(element.dataset.index), 1);
      renderTab();
      renderMap();
      break;
    case "queue-research":
      app.orders.research = element.dataset.tech;
      renderTab();
      break;
    case "remove-research":
      app.orders.research = null;
      renderTab();
      break;
    case "queue-construction":
      queueConstruction();
      break;
    case "queue-recruit":
      queueRecruit();
      break;
    case "remove-construction":
      app.orders.construction.splice(Number(element.dataset.index), 1);
      renderTab();
      break;
    case "remove-recruit":
      app.orders.recruits.splice(Number(element.dataset.index), 1);
      renderTab();
      break;
    case "diplomacy":
      queueDiplomacy(element.dataset.kind, element.dataset.target);
      break;
    case "remove-diplomacy":
      app.orders.diplomacy.splice(Number(element.dataset.index), 1);
      renderTab();
      break;
    case "take-control":
      await takeControl();
      break;
    case "close-modal":
      closeModal();
      break;
    case "confirm-save":
      await saveGame();
      break;
    case "load-save":
      await loadGame(element.dataset.name);
      break;
    case "dismiss-victory":
      closeModal();
      break;
    default:
      break;
  }
}

function onDocumentChange(event) {
  const target = event.target;
  if (target.matches("[data-event-option]")) {
    app.orders.event_choices[target.dataset.eventId] = target.dataset.optionId;
  }
}

async function startGame(nation) {
  const seed = $("#seed-input")?.value || null;
  const data = await api("/api/new", { nation, seed });
  if (!data.ok) {
    showMessage("Impossible de lancer la partie", data.error || "Erreur inconnue.");
    return;
  }
  app.orders = emptyOrders();
  app.selectedProvince = null;
  app.selectedArmy = null;
  app.activeTab = "orders";
  app.victoryKey = null;
  showGame(data.view);
}

function queueMove(armyId, provinceId) {
  const army = (app.view.own?.armies || []).find((item) => item.id === armyId);
  const province = (app.view.map.provinces || []).find((item) => item.id === provinceId);
  if (!army || !province) return;
  app.orders.moves = app.orders.moves.filter((move) => move.army !== armyId);
  app.orders.moves.push({
    army: armyId,
    to: provinceId,
    label: `${army.name} vers ${province.name}`,
  });
  app.selectedArmy = null;
  renderMap();
  renderProvincePanel();
  renderTab();
}

function queueConstruction() {
  const provinceId = $("#construction-province")?.value;
  const kind = $("#construction-kind")?.value;
  const province = (app.view.map.provinces || []).find((item) => item.id === provinceId);
  if (!province) return;
  app.orders.construction.push({ province: provinceId, provinceName: province.name, kind });
  renderTab();
}

function queueRecruit() {
  const provinceId = $("#recruit-province")?.value;
  const unit = $("#recruit-unit")?.value;
  const count = Math.max(1, Math.min(6, Number($("#recruit-count")?.value || 1)));
  const province = (app.view.map.provinces || []).find((item) => item.id === provinceId);
  if (!province) return;
  app.orders.recruits.push({ province: provinceId, provinceName: province.name, unit, count });
  renderTab();
}

function queueDiplomacy(kind, target) {
  const nation = (app.view.nations || []).find((item) => item.id === target);
  if (!nation) return;
  const labels = {
    improve: `Ameliorer les relations avec ${nation.short}`,
    alliance: `Proposer une alliance a ${nation.short}`,
    nap: `Proposer un pacte de non-agression a ${nation.short}`,
    trade: `Proposer un accord commercial a ${nation.short}`,
    transit: `Demander un droit de transit a ${nation.short}`,
    war: `Declarer la guerre a ${nation.short}`,
    peace: `Proposer la paix a ${nation.short}`,
  };
  app.orders.diplomacy.push({ action: kind, target, label: labels[kind] || kind });
  renderTab();
}

async function endTurn() {
  if (app.busy || app.view.victory) return;
  app.busy = true;
  renderTopbar();
  const data = await api("/api/end-turn", { orders: app.orders });
  app.busy = false;
  if (!data.ok) {
    renderTopbar();
    showMessage("Tour impossible", data.error || "Erreur inconnue.");
    return;
  }
  app.orders = emptyOrders();
  app.selectedArmy = null;
  app.activeTab = (data.view.pending_events || []).length ? "orders" : app.activeTab;
  showGame(data.view);
  if (data.view.victory) {
    showVictoryModal(data.view.victory);
  } else {
    showReportModal(data.view.report || []);
  }
}

async function takeControl() {
  const select = $("#take-control-nation");
  if (!select) return;
  const data = await api("/api/take-control", { nation: select.value });
  if (!data.ok) {
    showMessage("Prise de controle impossible", data.error || "Erreur inconnue.");
    return;
  }
  app.orders = emptyOrders();
  app.activeTab = "orders";
  app.selectedArmy = null;
  showGame(data.view);
}

/* ------------------------------------------------------------------ */
/* Sauvegarde / chargement                                             */
/* ------------------------------------------------------------------ */

function showSaveModal() {
  const suggested = `partie-${app.view.turn + 1}`;
  openModal(`
    <h2>Sauvegarder la partie</h2>
    <p>La sauvegarde est un fichier JSON local dans le dossier <code>saves/</code>.</p>
    <div class="form-row"><input id="save-name" type="text" value="${esc(suggested)}" style="flex:1"></div>
    <div class="modal-actions">
      <button class="ghost-button" data-action="close-modal">Annuler</button>
      <button class="primary-button" data-action="confirm-save">Sauvegarder</button>
    </div>`);
}

async function saveGame() {
  const name = $("#save-name")?.value || `partie-${app.view.turn + 1}`;
  const data = await api("/api/save", { name });
  if (!data.ok) {
    showMessage("Sauvegarde impossible", data.error || "Erreur inconnue.");
    return;
  }
  openModal(`
    <h2>Sauvegarde creee</h2>
    <p>${esc(data.save.name)} — ${esc(data.save.date)}, tour ${data.save.turn + 1}.</p>
    <div class="modal-actions"><button class="primary-button" data-action="close-modal">Fermer</button></div>`);
}

async function showLoadModal() {
  const data = await api("/api/saves");
  if (!data.ok) {
    showMessage("Chargement impossible", data.error || "Erreur inconnue.");
    return;
  }
  const saves = data.saves || [];
  const rows = saves.length
    ? saves.map((save) => `<li><span><strong>${esc(save.name)}</strong><br><span class="small muted">${esc(save.date || "")} · tour ${save.turn + 1}${save.player ? ` · ${esc(save.player)}` : ""}</span></span><button class="small-button" data-action="load-save" data-name="${esc(save.name)}">Charger</button></li>`).join("")
    : `<li><span class="muted">Aucune sauvegarde disponible.</span></li>`;
  openModal(`
    <h2>Charger une partie</h2>
    <ul class="save-list">${rows}</ul>
    <div class="modal-actions"><button class="ghost-button" data-action="close-modal">Fermer</button></div>`);
}

async function loadGame(name) {
  const data = await api("/api/load", { name });
  if (!data.ok) {
    showMessage("Chargement impossible", data.error || "Erreur inconnue.");
    return;
  }
  app.orders = emptyOrders();
  app.selectedProvince = null;
  app.selectedArmy = null;
  app.activeTab = "orders";
  app.victoryKey = null;
  closeModal();
  showGame(data.view);
}

/* ------------------------------------------------------------------ */
/* Modales                                                             */
/* ------------------------------------------------------------------ */

function openModal(html) {
  $("#modal").innerHTML = html;
  $("#modal-backdrop").classList.remove("hidden");
}

function closeModal() {
  $("#modal-backdrop").classList.add("hidden");
  $("#modal").innerHTML = "";
}

function showMessage(title, text) {
  openModal(`
    <h2>${esc(title)}</h2>
    <p>${esc(text)}</p>
    <div class="modal-actions"><button class="primary-button" data-action="close-modal">Fermer</button></div>`);
}

function showReportModal(report) {
  const entries = report.length
    ? report.map((entry) => `<div class="report-entry ${esc(entry.category)}">${esc(entry.message)}</div>`).join("")
    : `<div class="empty-state">Aucun evenement notable.</div>`;
  openModal(`
    <h2>Rapport du tour</h2>
    <p>${esc(app.view.date)} · tour ${app.view.turn + 1}</p>
    ${entries}
    <div class="modal-actions"><button class="primary-button" data-action="close-modal">Continuer</button></div>`);
}

function showVictoryModal(victory) {
  openModal(`
    <h2>${victory.player_won ? "Victoire" : "Fin de partie"}</h2>
    <p>${esc(victory.message)}</p>
    <p class="small muted">Type : ${esc(victory.type)} · ${esc(victory.date || "")}.</p>
    <div class="modal-actions">
      <button class="ghost-button" data-action="close-modal">Voir la carte</button>
      <button class="primary-button" data-action="dismiss-victory">Fermer</button>
    </div>`);
}

/* ------------------------------------------------------------------ */
/* Liaisons des boutons statiques                                      */
/* ------------------------------------------------------------------ */

document.addEventListener("DOMContentLoaded", () => {
  $("#observer-button")?.addEventListener("click", () => startGame(null));
  $("#load-button-selection")?.addEventListener("click", () => showLoadModal());
  $("#load-button")?.addEventListener("click", () => showLoadModal());
  $("#save-button")?.addEventListener("click", () => { if (app.view) showSaveModal(); });
  $("#end-turn-button")?.addEventListener("click", () => endTurn());
  $("#tabs")?.addEventListener("click", (event) => {
    const tab = event.target.closest("[data-tab]");
    if (!tab) return;
    app.activeTab = tab.dataset.tab;
    renderTab();
  });
  init();
});
