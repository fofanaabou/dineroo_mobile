# Dineroo — Redesign Context for the Figma AI Agent

> **Read this first.** This file is the single source of truth for redesigning the Dineroo app.
> Images referenced below live in `images/` next to this file. Attach this file **and** the `images/` folder.
> A short paste-in prompt is at the very end (section 14).

**Legend used throughout**
- **[Verified]** read directly from the shipped Flutter code or an image in `images/`.
- **[Inferred]** a reasonable reading of the evidence; treat as an assumption and challenge it.
- **[Decision]** a choice already made by the product owner; do not reopen it.

---

## 1. Product in one paragraph

Dineroo is a **meal-delivery app for Conakry, Guinea** [Verified]. One app serves **three user types**: customers who order food, drivers ("livreurs") who deliver it, and restaurant managers who prepare and hand over orders. The UI is **French only**, prices are in **Guinean francs (GNF)**, and payment is by an in-app **wallet** or **Mobile Money** through the Djomy gateway [Verified]. There is live order tracking on a map, real-time alerts, and a 4-digit code handshake that proves a hand-off happened.

It ships today as **iOS and Android** apps and is being extended to **web and tablet** from the same Flutter codebase [Decision]. The redesign must work on all of them.

## 2. Why we are redesigning — goals

| # | Goal | What "done" looks like |
|---|------|------------------------|
| G1 | **Modern** | A refreshed, coherent visual language. It no longer looks like default Material with orange paint. |
| G2 | **Responsive** | Every screen designed for phone, tablet and desktop-web, not a phone layout stretched wide. |
| G3 | **Cross-platform** | One design system that feels native-quality on iOS, Android and web, and is buildable in Flutter. |
| G4 | **Trustworthy with money** | Payment, wallet, earnings and totals feel safe and unambiguous. This is a fintech-adjacent flow. |
| G5 | **Fast to scan under pressure** | Managers accept orders at a busy counter; drivers read the screen on a moving bike. Glanceability is a requirement, not a nicety. |
| G6 | **Accessible** | WCAG 2.1 AA at minimum (see the contrast findings in section 5, which currently fail). |

### Direction already decided
- **[Decision] Keep the orange brand and modernize around it.** Orange `#F58D1D` stays the brand anchor. Palette, typography, component style and layout are all open for refresh. A fully new identity is out of scope.
- **[Decision] Adaptive layouts per screen size, not one centered phone column and not separate web designs.** Each screen gets a layout per size class.
- **[Decision] Phones must stay familiar.** The compact layout can be visually refreshed, but the navigation model (bottom bar) and core flows stay.

### Non-goals (do not design these)
- New features, new roles, or new business rules. This is a **re-skin and re-layout**, not a product change.
- URL routing or deep links on web (the app does not use URLs for screens).
- Push-notification web UX. Web alerts rely on an in-page real-time channel plus sound only.
- A different brand name or a new logo from scratch. You may propose refinements (see open decision D1).

---

## 3. Users and what each one needs

| Role | Who they are | Primary device (today) | The one thing the design must nail |
|------|--------------|------------------------|-------------------------------------|
| **Customer** ("client") | Hungry person in Conakry placing an order | Phone (iOS/Android); web is planned | Find a restaurant fast, trust the total, always know where the order is |
| **Driver** ("livreur") | Courier on a bike/moto, hands often busy, outdoors in sun | Phone | Go online, see the next job instantly, never miss a step of the hand-off, see earnings |
| **Restaurant manager** | Runs the kitchen/counter, has to react in seconds | Phone, tablet, web (all three in scope) | Never miss a new order; accept/refuse in one tap; keep the menu and hours correct |

**[Inferred] audience considerations** (challenge if you have better data): many users are on mid-range Android phones, with variable connectivity and sunlight glare. Favor high contrast, light imagery, resilient loading/empty/error states, and generous touch targets (48 dp+).

Managers **cannot self-register**: their login screen hides the "create an account" link, and if they try to sign up anyway a warning says to contact Dineroo for a restaurant account [Verified]. Drivers register themselves, upload an ID document, and wait for approval [Verified].

---

## 4. Platforms and responsive behaviour

### 4.1 Size classes [Decision, already implemented in code]

| Class | Width | Navigation | Content |
|-------|-------|------------|---------|
| **Compact** | < 600 px | Bottom navigation bar | Single column, edge-to-edge cards |
| **Medium** | 600–839 px | Side **navigation rail**, labels under icons | Centered/constrained, 2 columns where useful |
| **Expanded** | ≥ 840 px | **Extended** rail (icon + label side by side) | Constrained max-width, multi-column, master–detail where it helps |

Already-set max widths: auth card **480 px**, role-selection column **420 px**, dialogs **560 px**, bottom sheets 640 px. Tablets in portrait (≈768 px) get the rail.

### 4.2 Frames to design

| Frame | Size | Use |
|-------|------|-----|
| Phone (iOS) | 390 × 844 | Compact reference |
| Phone (Android) | 360 × 800 | Compact smallest real target |
| Tablet portrait | 834 × 1194 | Medium (iPad 11"/Android tablet) |
| Tablet landscape | 1194 × 834 | Expanded on tablet (manager use case) |
| Desktop web | 1440 × 900 | Expanded |
| Narrow web | 1024 × 768 | Medium/expanded boundary check |

### 4.3 Platform specifics the design must respect

| Platform | Notes |
|----------|-------|
| **iOS** | Safe areas (notch, home indicator). Bottom bar must clear the home indicator. |
| **Android** | 3-button and gesture navigation both exist; keep bottom content clear. Smallest phones ≈ 360 px wide. |
| **Web** | **Add hover, focus-visible and keyboard states** (they do not exist today). Enter should submit forms. Pull-to-refresh is awkward with a mouse, so provide an explicit refresh affordance. Mouse drag scrolls lists. Installable as a standalone **PWA** (theme/background color `#F58D1D`) [Verified]. Payment opens the Djomy page in a **new browser tab** and the app waits for confirmation. |
| **Tablet (native)** | Manager is the key tablet user (counter/kitchen). Design portrait **and** landscape. The app currently locks orientation; unlocking it is waiting on this redesign of the inner screens. |
| **All** | **Flutter renders its own widgets** (Material 3), not native controls. Design with Material 3 building blocks so it is buildable. Name tokens to match Flutter `ColorScheme` / `TextTheme` roles. |

---

## 5. Current design: what exists today [Verified]

### 5.1 Brand assets
- **Wordmark:** "Dineroo" in **Lobster** (a bold script). White on orange `#F58D1D` on the splash screen. See `images/brand/`.
- **App icon:** the launcher icon is a **different** wordmark, a bold geometric sans "Dineroo" on orange. See `images/brand/app-icon-launcher-1024.png`. The splash wordmark (script) and icon wordmark (sans) **do not match** (open decision D1).
- **Typefaces:** **Montserrat** (body/UI) and **Lobster** (wordmark). Only Montserrat **Regular (400)** and **SemiBold (600)** are bundled; a heavier weight would need to be added to the app.

### 5.2 Tokens actually in the code
There is **no design-token system**. About 40 hard-coded hex values plus Material named colors are scattered across screens. The most-used:

| Role (as used today) | Value | Notes |
|----------------------|-------|-------|
| Brand orange (splash, PWA, `AppColors.orange`) | `#F58D1D` | The only named brand color |
| Active tab / nav / links | Flutter `deepOrange` ≈ `#FF5722` | 42 uses |
| Primary buttons ("Payer", "SE CONNECTER") | `#FF7643`, `#FF7300`, `#FF5A14`, `#FF4B12` | **Four different oranges** for the same job |
| Primary text | `#32343E` (13 uses), `#181C2E`, `#1C1C1E` | Three near-identical darks |
| Deep navy (auth header) | ≈ `#0A0338`–`#181C2E` | See `images/current-web/03-login-desktop.png` |
| Surfaces / dividers | `#F8F8F8`, `#F5F5F5`, `#EAEAEA`, `#E0E0E0` | |
| Orange tints (chips, banners, selected) | `#FFE0D2`, `#FFF2F0`, `#FFF7F5`, `#FFF7F1` | |
| Light blue field fill | `#F2F6FF` | Input backgrounds |
| Inactive nav/tab | Flutter `grey` ≈ `#9E9E9E` | |
| Success / open | green (money total shows green) | |
| Error / closed / refuse | red tints | |

Type sizes used most: 16, 14, 12, 13, 18, 20, 24 px (no defined scale). Corner radii used: 12, 20, 16, 10, 8, 18, 24, 22, 14 and fully round (999). Cards use soft shadows.

### 5.3 Measured accessibility problems (contrast, computed from the code colors)

| Foreground on background | Ratio | WCAG AA (needs 4.5:1 body, 3:1 large) |
|--------------------------|-------|----------------------------------------|
| **White on brand orange `#F58D1D`** | **2.41:1** | **Fails**, even for large text |
| White on `#FF7643` (button) | 2.65:1 | **Fails** |
| White on `#FF4B12` | 3.35:1 | Passes large text only |
| White on deepOrange `#FF5722` | 3.16:1 | Passes large text only |
| Orange `#F58D1D` text on white | 2.41:1 | **Fails** |
| deepOrange `#FF5722` text on white (active nav label) | 3.16:1 | Fails for small text |
| Inactive nav grey `#9E9E9E` on white | 2.68:1 | **Fails** |
| Navy `#181C2E` on brand orange `#F58D1D` | 7.00:1 | Passes comfortably |
| `#32343E` on white | 12.38:1 | Passes |

**What this means for you:** white text on the brand orange is the app's signature look and it is not accessible. Options to explore: (a) dark navy text/icons on orange surfaces (7:1); (b) a darker "action orange" for filled buttons that reaches ≥ 4.5:1 with white (for example ≈ `#C2410C` gives about 5.2:1; verify any shade you pick); (c) keep `#F58D1D` for large decorative surfaces, backgrounds and illustration only. Pick one rule and apply it everywhere.

Order-status chips are all **white text on a Material color**, including amber, which is far below AA (see section 9).

### 5.4 Visible layout problems (see `images/current-web/`)
1. **Web is the phone layout stretched.** At 1688 px the restaurant list is a full-bleed single column of thin rows and the login is a full-width form (`02-…`, `03-…`). The role-selection buttons span the entire window (`01-…`).
2. **Inconsistent primary buttons** (four oranges, differing radii) and inconsistent card styles.
3. **Dense, undifferentiated lists.** Restaurant rows show image, name, status pill, distance and description at nearly equal weight, and the "Restaurant fermé" pill repeats on every closed row.
4. **Weak imagery hierarchy on the list.** Restaurant photos are small thumbnails. (The restaurant *detail* screen does have a hero.) Do not add rating or delivery-time signals; the data does not exist (section 11).
5. **Brand split:** script wordmark in-app vs. sans wordmark on the icon.
6. **Legacy icons** are low-resolution or off-brand (see section 12, `legacy-icons/`).
7. **Light theme only.** No dark theme exists.

---

## 6. Design-system brief (what to produce)

Produce a Figma **library with variables**, not just screens. Suggested structure:

1. **Color variables:** brand (orange scale), neutral scale, semantic roles (`primary`, `on-primary`, `surface`, `surface-variant`, `outline`, `text-primary`, `text-secondary`, `success`, `warning`, `error`, `info`) plus **order-status** roles (section 9). Each foreground/background pair documented with its contrast ratio. **Light theme required.** A dark theme is a stretch goal: define tokens but do not design every screen.
2. **Typography scale:** a named scale (display, headline, title, body, label, caption) on Montserrat, with the wordmark in Lobster only. Include **money styles** (tabular/lining figures, large total) since prices like `47 050 GNF` are everywhere. Limit to weights 400 and 600 unless you request adding 700.
3. **Spacing + sizing:** 4 or 8 px base grid. Minimum touch target 48 × 48. A defined **page gutter per size class**.
4. **Radius + elevation:** replace the 10+ ad-hoc radii with 3–4 named steps and 2–3 shadow levels.
5. **Iconography:** one icon family at consistent stroke/size (the app uses Material icons today; a single outlined+filled pair for active/inactive nav). Replace the legacy illustrations.
6. **Imagery:** rules for restaurant/menu photos (aspect ratios, crop, overlay for text legibility, fallback when no photo or load error).
7. **Motion:** short guidance only (press, sheet, status change, "searching for rides" pulse). Keep it lightweight; low-end devices.

### Component inventory (design every one with all states)

| Component | Variants / states to include |
|-----------|------------------------------|
| **Buttons** | Primary, secondary, tertiary/text, destructive (REFUSER), success (ACCEPTER), icon-only, loading, disabled; sizes sm/md/lg; full-width and intrinsic |
| **Text field** | Phone (`6XX XX XX XX`), PIN (masked, eye toggle), OTP code boxes, multiline with counter (`0/300`); default/focus/filled/error/disabled; hover on web |
| **Navigation** | Bottom bar (4 or 5 items, badge on Panier), navigation rail (collapsed + extended), top app bar (title centered, back, trailing cart icon with badge) |
| **Cards** | Restaurant card, menu card (horizontal carousel), product row, cart line (image, name, price, qty stepper), order card (status chip + actions), stat tile, earnings hero, delivery card |
| **Chips / pills** | Open (`Restaurant ouvert`), closed (`Restaurant fermé`), category (Entrée/Plat/Boisson/Dessert), order-status chips (12 values), `NOUVEAU` badge, price pill |
| **Quantity stepper** | − / count / +, min/max, disabled |
| **Banners** | Active-order banner (`Suivre ma commande`), restaurant-closed banner, suspension banner, offline banner |
| **Dialogs + sheets** | Confirm/destructive dialog, info dialog, bottom sheet (compact) that becomes centered dialog or side panel (expanded) |
| **Feedback** | Snackbar/toast, skeleton loader, spinner, empty state (illustration + 1 line + action), error state with retry |
| **Timeline stepper** | Vertical order-tracking steps with done / current / upcoming / failed |
| **Map elements** | Pin markers (me, restaurant, customer, driver), route line, floating action chips on map, bottom info sheet |
| **Lists/tables** | Transaction row (wallet), delivery-history row, catalog item row with availability switch |
| **Switch / toggle** | Catalog availability, opening-hours day on/off |
| **Time picker row** | Opening-hours day editor with up to two non-overlapping time ranges |
| **Avatar** | Profile photo with upload affordance, driver avatar in tracking |
| **Code entry** | 4-digit code entry and a large 4-digit code display (customer hand-off code) |

---

## 7. Information architecture and navigation

Bottom bar on compact, rail on medium/expanded. Items below are the current tabs [Verified].

| Role | Tab 1 | Tab 2 | Tab 3 | Tab 4 | Tab 5 |
|------|-------|-------|-------|-------|-------|
| **Customer** | Accueil | Panier (badge) | Commandes | Profil | — |
| **Driver** | Accueil | Historique | Gains | Profil | — |
| **Manager** | Accueil | Commandes | Gains | Catalogue | Profil |

Notes
- The App Store mockup labels the manager's 4th tab "Menus"; the **code says "Catalogue"**. Treat the code as correct.
- Customer **Wallet** ("Mon Wallet") lives inside Profil as an action tile, not a tab.
- The nav hides on specific full-screen flows (for example the driver's active delivery) [Verified].
- A **rail needs ≥ 2 destinations**; every role has at least 4.

**Entry flow (all roles):** Splash → (already signed in? go to the role home) else → Role selection → Login (per role) → Location permission gate → Role home. The location gate is also re-shown from the cart when the customer's location is missing. [Verified that it is reachable from login, code verification, startup and the cart; which roles are exempt is not verified.]

---

## 8. Screen inventory

~48 screens (a few are shared between roles). IDs are used for the file-mapping appendix. Design **each at compact, medium and expanded** unless marked otherwise. For every screen also design the relevant **loading, empty, error and offline** states.

### 8.1 Shared and auth

| ID | Screen | Purpose and content [Verified from code/strings] | Image reference |
|----|--------|--------------------------------------------------|-----------------|
| S01 | **Splash / boot** | Orange `#F58D1D` full-bleed with white script wordmark | `brand/` |
| S02 | **Role selection** ("Qui êtes-vous ?") | Wordmark, two big buttons `JE SUIS UN CLIENT` (white) and `JE SUIS UN LIVREUR` (orange-red), and a small secondary pill `ESPACE RESTAURANT` at the bottom | `current-web/01-…`, `store-mockups-phone/01-role-entry.png` |
| S03 | **Login** (title adapts: *Connexion Client* / *Connexion Livreur* / *Espace Restaurant*) | Dark navy header with title + subtitle (`Veuillez vous connecter à votre compte`), white rounded sheet with fields `TÉLÉPHONE` (`6XX XX XX XX`) and `CODE PIN` (masked, eye toggle), link `Code PIN oublié`, primary `SE CONNECTER`, footer `Pas encore inscrit ? Créer un compte`. **For managers the footer is hidden** (they cannot self-register) | `current-web/03-…` |
| S04 | **Sign-up** (customer, driver) | First name, last name, phone, PIN; `SUIVANT`. Error cases: number already registered, account disabled. If a manager reaches it, a warning toast says `Contactez Dineroo pour créer un compte restaurant.` | — |
| S05 | **Verify code (OTP)** | "Un code a été envoyé à …", code entry, `Renvoyer`, errors: invalid/expired, timeout | — |
| S06 | **Forgot / change PIN** | `Nouveau code PIN`, `Confirmer le code PIN`, `RÉINITIALISER`; mismatch error | — |
| S07 | **Driver identity upload** | Add an ID document so Dineroo can verify the courier profile; file picker; sets status to pending | `legacy-icons/` (upload icon is tiny) |
| S08 | **Thanks / pending approval** (driver) | `Merci pour votre inscription !`: waiting for Dineroo to approve the courier | — |
| S09 | **Location access** | `AUTORISER LA LOCALISATION`; privacy line: location is only used to suggest nearby restaurants. Plus **blocked** dialog with `Aller aux paramètres` / `Compris`. Shown after login and from the cart when location is missing | — |
| S10 | **App update dialog** | Optional (`Plus tard` / `Mettre à jour`) and **forced** (no dismiss) variants | — |
| S11 | **Profile** | Avatar with upload, name, phone; action tiles: *Mon Wallet* (customer), *Changer les horaires du restaurant* (manager), *Changer le code PIN*, *Déconnexion*; edit mode (`MODIFIER` / `ENREGISTRER`); load-error state (`Impossible de charger votre profil.` + `Se reconnecter`) | — |
| S12 | **Order detail** (shared by manager and driver) | `Détail de la commande`: items (`Contenu de la commande`), customer, assigned driver, delivery info, comment, price breakdown (`Sous-total produits`, `Frais de livraison`, `Frais de service`, `Total payé`) | — |
| S13 | **Earnings / Gains** (driver and manager) | Hero `Montant Disponible` (the marketing mockup shows an orange gradient), 4 stat tiles (`Courses terminées` / `Commandes terminées`, `Déjà payé`, `Total gagné`, `Devise`), note that withdrawals are handled by Dineroo, CTA `RETIRER MON ARGENT` opening an info dialog | `store-mockups-phone/05-driver-earnings.png` |
| S14 | **Map** (component used by customer tracking and driver home) | Map with current-location marker and routes; tiles are standard OpenStreetMap (limited styling, see D4) | `store-mockups-phone/04-driver-map.png` |

### 8.2 Customer

| ID | Screen | Purpose and content [Verified] | Image reference |
|----|--------|--------------------------------|-----------------|
| C01 | **Home: restaurants nearby** | Title `Restaurants à proximité`, cart icon w/ badge, search `Rechercher sur Dineroo`, **recent searches**, **active-order banner** (`Suivre ma commande` / `Consultez l'avancement de votre commande.` + `Suivre`), list of restaurant cards (photo, name, open/closed pill, distance in km, one-line description). Empty: `Aucun restaurant trouvé` | `current-web/02-…`, `store-mockups-phone/02-restaurants-nearby.png` |
| C02 | **Restaurant detail** | Hero photo with back + cart buttons, name, address (e.g. neighborhood, Conakry), description, open/closed pill, counts (`3 menus`, `17 produits`), banner `Découvrez la sélection du restaurant`, **category chips** (Entrée, Plat, Boisson, Dessert), **Menus** carousel (`Dès 47 250 GNF`, subtitle `Prix de base + suppléments éventuels`), product list | `store-mockups-phone/03-restaurant-detail.png` |
| C03 | **Menu detail (configurable)** | `Choisis un menu et configure tes accompagnements.`: groups of choices (some `Obligatoire`), extras change the price (`Les suppléments s'ajoutent selon tes choix`), quantity, price, add-to-cart bar. State: `Ce menu n'est pas encore configurable` | — |
| C04 | **Product detail** | Photo, name, description, price, quantity, add-to-cart. Toast `Ajouté au panier avec succès` | — |
| C05 | **Cart (list)** | One **grouped cart card per restaurant** (an order is per restaurant [Inferred from the grouped-cart structure]). Empty state: `Ajoute tes produits préférés directement au panier.` | `current-web/04-…` (detail) |
| C06 | **Cart detail (checkout)** | Title = restaurant; `LIVRER À` address chip (clearable); `Mon panier` lines with image + qty stepper; `Ajouter un commentaire` (0/300, e.g. "sans oignons"); `Résumé de la commande`: `Sous-total`, `Frais de livraison`, `Frais de service`, **`Total à payer`** (large, green), `Paiement 100% sécurisé`; sticky bottom bar with total + `Payer`. States: restaurant closed banner, `Calcul des frais en cours...`, `Estimation indisponible`, location-off prompt (`Activer`) | `current-web/04-…` |
| C07 | **Delivery contact form** (bottom sheet) | Prénom, Nom (optionnel), Adresse (`Ex: 12 Avenue de la République`), Quartier, Commune (optionnel), `Autres informations (optionnel)` (e.g. "près de la pharmacie, portail bleu…") | — |
| C08 | **Payment method** (sheet) | `Mode de paiement`: **Wallet** or **Mobile Money** (Djomy) | — |
| C09 | **Payment in progress** | Gateway page (in-app webview on phones, **new tab on web**), then `Confirmation du paiement…`. Outcomes: confirmed, pending confirmation, refused, interrupted, failed | — |
| C10 | **Order placed** | Success confirmation `Commande passée !` / `Merci pour votre commande !` | `legacy-icons/order_placed_image.png` (low-res) |
| C11 | **Orders** | Tabs `En cours` / `Historique`; order cards with status chip, restaurant, total, actions (`Suivre`, `Détail`). Empty: `Aucune commande à afficher` | — |
| C12 | **Order tracking** | Map on top, order id (`Commande #A3C1`), restaurant chip, **hand-off code card** (`Code à donner au livreur`, 4 digits), vertical timeline (`Commande passée` → `Commande confirmée` → `En cours de livraison` → `Livrée` → `Commande terminée`) with sub-text per state, driver avatar + name + **call** button. Failure states: `Commande refusée`, `Commande annulée`, `Paiement échoué`, `Commande arrêtée` | `store-mockups-phone/07-client-tracking.png` |
| C13 | **Wallet** | `Mon Wallet`: balance, transaction list (CREDIT/debit). Empty: `Aucun solde disponible`, `Aucune transaction pour le moment.`; error: `Impossible de charger votre Wallet.` | — |

### 8.3 Driver

The driver's job is a **phase machine**: `idle → incoming → toRestaurant → toCustomer` [Verified], with status `OFFLINE / ONLINE / ON_DELIVERY`. The screen stays awake while online (wake-lock).

| ID | Screen | Purpose and content | Image reference |
|----|--------|---------------------|-----------------|
| D01 | **Home: offline** | Full map, **primary control `Passer en ligne`** | `store-mockups-phone/04-driver-map.png` |
| D02 | **Home: online, searching** | Map, animated `Recherche de courses`, **`Passer hors ligne`** (red) | `store-mockups-phone/04-driver-map.png` |
| D03 | **Incoming ride** (card shown over the map) | A new job offer showing `Montant de la course` (the amount) plus pickup details. The accept/decline control labels were not verified; keep the existing intent | — |
| D04 | **To restaurant** (card) | `Restaurant` name, **`Code à donner au restaurant`** (the driver's code, shown large so the manager can read it), primary button **`J'ai récupéré la commande`**, plus the **external-map** button (`Afficher la course`) | — |
| D05 | **To customer** (card) | `Client` name, primary button **`Je livre la commande`**, which opens a confirm dialog (`Confirmer la livraison !` / `Êtes-vous sûr de vouloir livrer la commande ?`) | — |
| D06 | **Delivery confirmation** (full screen) | `Confirmation de livraison`: `Veuillez saisir le code à 4 chiffres du client`, 4-digit entry, `VALIDER`, link `Le client ne trouve pas le code` which opens a hint (`Astuce`). Errors: incomplete code, wrong code, code unavailable | — |
| D07 | **Ride success** | `Bravo`: `Vous avez terminé la course. Montant ajouté à vos gains :` + amount | `legacy-icons/app_withdraw.png` (success art) |
| D08 | **History** | `Historique des livraisons`: card per delivery with destination and `Gain livreur` banner. Empty: `Aucune livraison à afficher` | — |
| D09 | **Gains** | See S13 | `store-mockups-phone/05-driver-earnings.png` |
| D10 | **Profile** | See S11 | — |

### 8.4 Restaurant manager

| ID | Screen | Purpose and content | Image reference |
|----|--------|---------------------|-----------------|
| M01 | **Home / order desk** | Restaurant name, **open/closed status** pill, two big counters (`NOUVELLES COMMANDES`, `COMMANDES PRÊTES`), **reception cards** for incoming orders: `NOUVEAU` badge, order id (`Commande #228B`), price pill, first item + `+ 1 autre`, side-by-side **`REFUSER` / `ACCEPTER`**. **Only the top card of the queue is actionable; the following ones are shown dimmed/disabled** [Verified in code]. Empty: `Aucune commande pour le moment` / `Les nouvelles commandes apparaîtront ici dès qu'elles seront passées.` | `store-mockups-phone/06-restaurant-orders.png`, `store-mockups-tablet/ipad13-06-restaurant-orders.png` |
| M02 | **Orders** | Tabs `Préparation` / `Prêtes` / `Historiques`. Actions per card: `Marquer prête`, `Remettre au livreur`, `Détail`, `Suivre` | — |
| M03 | **Hand-off to driver** | Enter the **driver's 4-digit code** (`Saisissez le code à 4 chiffres communiqué par le livreur.`) → `Valider`; shows assigned driver or `Aucun livreur assigné pour le moment` | — |
| M04 | **Refuse confirmation** | Dialog `Êtes-vous sûr de vouloir refuser cette commande ?` (`Oui, refuser` / `Annuler`) | — |
| M05 | **Gains** | See S13 (labels: `Commandes terminées`; note `Calculé sur les commandes livrées ou terminées.`) | `store-mockups-phone/05-driver-earnings.png` (driver version) |
| M06 | **Catalogue** | Tabs `Menus` / `Produits`; each item has an **availability switch** with a confirm dialog (`Rendre ce produit indisponible ?`); entry to stats. The catalogue is **imported by Dineroo**: managers can toggle availability but **cannot create items**. An `Ajouter un nouveau menu` / `Ajouter un nouveau produit` row exists, but it only opens a dialog (`Merci de contacter le support pour ajouter un menu.`). Empty: `Aucun menu disponible. Contactez Dineroo pour importer votre catalogue.` Design that row honestly as a "contact support" action, not as a working create flow | — |
| M07 | **Catalogue statistics** | `Statistiques du catalogue`: overview of available/unavailable products and menus, `Tout est disponible`, `Structure à vérifier` | — |
| M08 | **Menu composition** | `Composition du menu`: groups, items, required (`Obligatoire`), per-item availability; `Menu bloqué` state | — |
| M09 | **Opening hours editor** | Per weekday: closed or one/two time ranges, `Ajouter une autre plage`, `Supprimer cette plage horaire`; validation: ranges must not overlap, end ≠ start | — |
| M10 | **Suspension state** | `Restaurant suspendu` banner on Home plus a notice: `Contactez le support Dineroo pour plus d'informations.`; actions disabled with `Action indisponible : votre restaurant est suspendu.` Reasons listed in section 9.5 | — |
| M11 | **Profile** | See S11 | — |

**Manager on tablet/landscape is the priority adaptive case.** Suggested shape (your call): master–detail on Orders (list left, order detail right) and a multi-column order desk on Home.

---

## 9. Domain reference the design must respect [Verified]

### 9.1 Order lifecycle (12 statuses) and today's chip colors

| Status (API) | Label shown today (French) | Color today (white text on it) | Suggested semantic group |
|--------------|----------------------------|--------------------------------|--------------------------|
| CREATED | En attente de paiement | orangeAccent ≈ `#FFAB40` | Waiting |
| PENDING_PAYMENT | En attente de paiement | deepOrange ≈ `#FF5722` | Waiting |
| PAYMENT_CONFIRMED | Paiement confirmé | amber ≈ `#FFC107` | In progress |
| PAYMENT_FAILED | Paiement échoué | redAccent ≈ `#FF5252` | Failure |
| ACCEPTED | Acceptée | blue ≈ `#2196F3` | In progress |
| REJECTED | Refusée | redAccent ≈ `#FF5252` | Failure |
| PREPARING | En préparation | teal ≈ `#009688` | In progress |
| READY_FOR_PICKUP | Prête à être récupérée | purple ≈ `#9C27B0` | Hand-off |
| PICKED_UP | Récupérée par le livreur | indigo ≈ `#3F51B5` | In delivery |
| DELIVERED | Livrée | green ≈ `#4CAF50` | Success |
| COMPLETED | Terminée | green ≈ `#4CAF50` | Success |
| CANCELED | Annulée | red ≈ `#F44336` | Failure |

**Problem:** ten different hues, white text on all, several below AA. **Ask:** collapse into ~5 semantic groups (Waiting, In progress, Hand-off/In delivery, Success, Failure) with AA-safe foreground/background pairs, plus an icon per group so status never relies on color alone. "Ongoing" statuses drive the customer's `En cours` tab.

### 9.2 Delivery and driver status
- Delivery: `PENDING → ASSIGNED → PICKED_UP → DELIVERED` (or `CANCELED`).
- Driver availability: `OFFLINE`, `ONLINE`, `ON_DELIVERY`.

### 9.3 The 4-digit code handshake (core trust mechanism)
1. **Driver → restaurant (pickup):** the driver's card shows `Code à donner au restaurant` (D04); the driver reads it out and the manager types it to hand the order over (M03).
2. **Customer → driver (drop-off):** the customer's tracking screen shows `Code à donner au livreur` (C12); the driver types it on the delivery-confirmation screen (D06).
   - **Rule [Verified in the driver's hint text]:** the delivery code is the **last 4 digits of the customer's phone number**. The driver sees this as a hint (`Astuce`) when the customer can't find the code. Surface this in the design (for example a short explanatory line under the customer's code).

Both entry and display of these codes need to be **large, legible, error-tolerant** and calm in the failure state (`Code incorrect. Veuillez réessayer.`).

### 9.4 Payments [Verified]
- Methods: **Wallet** (in-app balance) or **Mobile Money (Djomy)**.
- Payment statuses: pending, success (COMPLETED), failed, canceled, unknown.
- Customers also have a wallet with credits and debits (notification types include wallet credited, debited and re-credited).
- Currency is configurable but ships as **GNF**.

### 9.5 Manager suspension reasons (shown to the manager)
Réclamations qualité / hygiène · Articles manquants dans les commandes livrées · Délais de préparation excessifs · Ne répond pas aux demandes d'acceptation de commande · Violation des conditions générales · Autre.

### 9.6 Real-time and notifications
Alerts arrive for: payment confirmed, order accepted / rejected / preparing / ready, delivery assigned, driver pickup validated, order delivered, wallet movements, courier-account decision. On native these are push notifications; on web they appear **only while the tab is open**, via a real-time channel plus a **sound**. **Design an in-app alert pattern** (toast, banner, badge, optional sound toggle) that works without push, especially for managers' new orders.

---

## 10. Content and localization

- **Language:** French only today. Design for **text expansion** and long French strings; do not assume English lengths. Leave room for a future language switch but do not design one.
- **Tone:** direct, warm, informal-to-neutral. Customer copy uses "vous" mostly; some browse copy uses "tu" (`Ajoute tes produits préférés`). **Pick one register** per role (recommend *vous* for money/payment, *tu* acceptable for light discovery copy). Flag inconsistencies rather than silently changing them.
- **Case:** primary buttons are currently **ALL CAPS** (`SE CONNECTER`, `ACCEPTER`, `JE SUIS UN CLIENT`). You may keep or soften this; apply one rule.
- **Money:** `47 050 GNF` — French grouping (space as thousands separator), **no decimals**, currency code after the amount. Use a consistent money style (see section 6).
- **Distance:** `1.2 km` (decimal point as shown in the current UI).
- **Phone:** Guinean mobile format placeholder `6XX XX XX XX`.
- **Order ids:** short alphanumeric (`#A3C1`, `#228B`).
- **Sample real data to use in mockups** (taken from the marketing mockups, safe to reuse): restaurants *Mimiche's Food*, *La Cuisine de Hawa*, *Morgan Restaurant*, *Nomad*, *Le-Patio*; menu *Menu Bistrot* (`Dès 47 250 GNF`), *Menu Découverte* (`Dès 81 900 GNF`); item *Poulet Braisé* (`180 000 GNF`); driver name *Kémoko*; neighborhoods *Lambanyi*, *Kipé*, *Ratoma*, *Matoto*, *Nongo*; place names *Conakry*, *Corniche*, *Route de Donka*.
- **Do not reuse** the placeholder/test data visible in the web screenshots (restaurant distances of ~4,380 km and the `bbb, bbbbb` address are development artifacts).

### Microcopy bank (verbatim current strings, to preserve meaning)
- Empty/nudge: `Aucun restaurant trouvé` · `Aucune commande à afficher` · `Aucune livraison à afficher` · `Aucune commande pour le moment`
- Trust: `Paiement 100% sécurisé` · `DINEROO n'accède à votre position que pour vous proposer les restaurants proches.`
- Errors: `Une erreur est survenue. Veuillez réessayer.` · `Temps d'attente dépassé. Réessayez.` · `Paiement refusé. Veuillez réessayer.` · `Impossible de créer la commande. Veuillez réessayer.`
- Status: `Restaurant ouvert` / `Restaurant fermé` · `En cours de livraison` · `Commande terminée`

---

## 11. Rules for the designer (do / don't)

1. **Do not invent features or data** the app does not have: no ratings, no delivery-time promises, no promo codes, no loyalty, no cuisine filters, no live driver ETA. If a layout benefits from a signal that does not exist, show a placeholder and **list it as a request in your notes**, do not bake it in.
2. **Keep flows intact.** Re-skin and re-layout; do not add or remove steps.
3. **Everything gets states.** Default, hover (web), focus-visible, pressed, disabled, loading, empty, error, offline.
4. **Never rely on color alone** for status, errors or availability. Pair with an icon or text.
5. **Money is sacred.** Totals, fees and balances must be unambiguous and consistently styled. The `Payer` action must be unmistakable and not confusable with `Annuler`.
6. **Buildable in Flutter / Material 3.** Prefer standard behaviors (app bar, navigation bar/rail, sheets, switches, chips). If you introduce a custom component, justify it.
7. **Respect the manager's speed.** Accept/refuse must stay one tap, large, and impossible to confuse (colors plus labels plus position).
8. **No dark patterns** around payment or cancellation.

---

## 12. Image index

All files are in `images/`. **Reliability matters:** *capture* = a real screenshot of the running app; *mockup* = a marketing recreation generated from HTML/CSS (not the app itself). Where a mockup and the code disagree, the code wins.

### `images/current-web/` — real captures of the web build (desktop Chrome, light theme)
| File | Size | What it shows | Use it to |
|------|------|---------------|-----------|
| `01-role-selection-desktop.png` | 3375×1876 | Role screen at ~1688 px wide: orange background, script wordmark, `Qui êtes-vous ?`, two full-width buttons, `ESPACE RESTAURANT` pill at the bottom | See the stretched-phone problem on web |
| `02-restaurant-list-desktop.png` | 3375×1876 | Customer home at ~1688 px: search, `Suivre ma commande` banner, a long full-width list of restaurant rows, bottom bar (taken **before** the adaptive rail existed). Data is dev/test data | Evidence for the list/density problems |
| `03-login-desktop.png` | 3375×1876 | *Connexion Client*: navy header, `TÉLÉPHONE` and `CODE PIN` fields (light-blue fill), `Code PIN oublié`, orange `SE CONNECTER`, `Créer un compte` link, all stretched edge to edge | See the current auth styling |
| `04-cart-checkout-desktop-with-rail.png` | 1730×1876 | Cart detail at ~865 px wide **with the new extended side rail** (Accueil / Panier / Commandes / Profil): address chip, cart lines with qty steppers, comment box, order summary with green total, bottom `Payer` bar | See the current checkout and the first adaptive attempt |

### `images/store-mockups-phone/` — marketing **mockups**, 1242×2688 (orange background + device card)
| File | What it shows | Notes |
|------|---------------|-------|
| `00-brand-hero.png` | Brand hero | Brand mood reference |
| `01-role-entry.png` | Role selection on orange; light variant background | Headline "Une app, trois espaces" |
| `02-restaurants-nearby.png` | Customer home: search, 4 restaurant cards with photos and green *Restaurant ouvert* pills, bottom bar with cart badge | Best view of an "ideal" data state |
| `03-restaurant-detail.png` | Hero photo, name, address, open pill, count chips, category chips, Menus carousel (`Dès 47 250 GNF`) | |
| `04-driver-map.png` | Driver home: map, red `Passer hors ligne`, `Recherche de courses` sheet, driver nav: Accueil / Historique / Gains / Profil | |
| `05-driver-earnings.png` | Gains: orange gradient hero `125 000 GNF`, four stat tiles, info card, `RETIRER MON ARGENT` | Good reference for money presentation |
| `06-restaurant-orders.png` | Manager order desk: counters `31` / `2`, front card with `REFUSER` (red) / `ACCEPTER` (green), dimmed queued cards | Shows a **"Menus"** tab label; the code says **"Catalogue"** |
| `07-client-tracking.png` | Tracking: map, `#A3C1`, code card `1111`, vertical timeline, driver *Kémoko* + red call button | |

### `images/store-mockups-tablet/` — tablet **mockups**
`ipad13-06-restaurant-orders.png`, `ipad13-01-role-entry.png`, `ipad13-04-driver-map.png` (2048×2732, iPad portrait: **the phone layout simply scaled up**, the thing to improve), `tablet-00-brand-hero.png` (2560×1600) and `feature-graphic.png` (1024×500, Play Store header).

### `images/brand/`
| File | Notes |
|------|-------|
| `app-icon-launcher-1024.png` | Bold sans "Dineroo" in white on orange (does not match the script wordmark) |
| `wordmark-lobster-white-on-transparent.png` | Script wordmark, **white on a transparent background** (will look blank on white; view it on orange) |

### `images/legacy-icons/` — in-app illustrations, **replace or restyle**
| File | Size | Note |
|------|------|------|
| `support.png` | 1080² | Flat cartoon call-center agent (teal shirt, yellow tie): clashes with the brand style |
| `app_withdraw.png` | 1024² | Green check with sparkles; used for success/withdraw |
| `app_cloche_icon.png` | 124×98 | Tiny outline bell in a circle: **too low-res** |
| `order_placed_image.png` | 98×98 | Grey line box with a check: **too low-res** |
| `app_add_file.png` | 31×29 | Upload icon, very low-res |
| `app_spinner.png` | 23×27 | Loading glyph, very low-res |

### Screens with **no image available**
Everything behind login except cart detail: customer orders/wallet/payment, the whole driver flow beyond the map mockups, most manager screens (catalogue, opening hours, suspension), and all auth steps after login. These need a real account on a running backend to capture. **Design them from sections 8–9.** If you need a capture of a specific screen, list it in your notes and it will be supplied.

---

## 13. Deliverables and order of work

**Please deliver, in this order**

1. **Direction board:** 2 options for the modernized look (both keep orange `#F58D1D` as the anchor), each showing: palette with contrast ratios, type scale, one customer screen, one manager screen, one status-chip set. *Stop for review.*
2. **Foundations:** variables (color, type, spacing, radius, elevation), icon set, status system.
3. **Component library:** every component in section 6 with all states, using auto layout and responsive constraints.
4. **Core screens**, each at Compact / Medium / Expanded:
   - **Customer:** S02, S03, C01, C02, C03, C06, C08, C12
   - **Driver:** D01, D02, D04, D05, D06, S13 (Gains)
   - **Manager:** M01, M02, M03, M06
5. **Remaining screens** from section 8.
6. **Clickable prototypes** for three journeys: *customer orders and tracks a meal*, *driver completes a delivery*, *manager accepts, prepares and hands off*.
7. **Handoff notes:** token → Flutter `ThemeData`/`ColorScheme`/`TextTheme` mapping, component → Material 3 widget mapping, a list of **new requirements you introduced** (data, assets, fonts), and a list of open questions.

**Acceptance criteria**
- All text/background pairs meet **WCAG AA** and the ratios are documented.
- Status is never conveyed by color alone.
- No new features or fabricated data.
- Manager Home works at 834 × 1194 portrait and 1194 × 834 landscape.
- Web states (hover, focus, keyboard) exist for every interactive component.
- Token names map cleanly to Flutter Material 3 roles.

### Open decisions (please propose; do not silently choose)
| # | Decision | Context |
|---|----------|---------|
| D1 | **One wordmark.** Script (Lobster) vs. sans, and what the app icon becomes | Splash is script; launcher icon is sans |
| D2 | **Action color.** Dark text on orange vs. a darker orange for filled buttons | See section 5.3 |
| D3 | **Manager tablet layout.** Master–detail vs. multi-column desk | Primary adaptive use case |
| D4 | **Map styling.** The map uses default OpenStreetMap tiles with limited styling. Is a branded map style worth an engineering change? | Affects driver and tracking screens |
| D5 | **Text register.** *vous* vs. *tu* | See section 10 |
| D6 | **Dark theme.** Tokens only, or full screens? | Not supported today |

---

## 14. Paste-in prompt for the Figma AI agent

> You are redesigning **Dineroo**, a meal-delivery app for Conakry, Guinea (French UI, prices in GNF) with three roles: customer, driver, restaurant manager. It runs on iOS, Android and web from one Flutter codebase, so the design must be responsive (compact < 600, medium 600–839, expanded ≥ 840) and buildable with Material 3.
>
> **Read the attached `FIGMA_CONTEXT.md` fully and use the images in `images/`.** It contains the goals, constraints, current tokens and accessibility failures, the full screen inventory, order/payment rules, French copy, and an image index that says which images are real captures vs. marketing mockups.
>
> **Direction:** keep the orange brand (`#F58D1D`) as the anchor and modernize everything around it. Fix the contrast failures (white on orange is 2.41:1). Do not add features or invent data. Start with section 13, step 1: produce two direction options and **stop for my review** before building the full system.

---

## Appendix A — Screen ID → Flutter source (for developer handoff)

| ID | Source (under `lib/`) |
|----|----------------------|
| S02 | `shared/views/auth/whoiam_view.dart` |
| S03 | `shared/views/auth/login_view.dart` (+ `auth_layout.dart`) |
| S04 | `shared/views/auth/sign_up_view.dart` |
| S05 | `shared/views/auth/verify_code_view.dart` |
| S06 | `shared/views/auth/forgot_pin_view.dart` |
| S07 / S08 | `shared/views/auth/identity_upload_view.dart` / `thanks_sign_up_view.dart` |
| S09 | `shared/views/location/location_access_view.dart`, `location_permission_blocked_dialog.dart` |
| S10 | `shared/views/app_update/show_update_dialog.dart` |
| S11 | `shared/views/profile/` |
| S12 | `shared/views/orders/order_detail_view.dart` (+ `order_action_buttons/`) |
| S13 | `shared/gain/gain_view.dart`, `gain_content.dart` |
| S14 | `shared/views/map/` |
| Shell (rail / bottom bar) | `shared/views/adaptive_nav_scaffold.dart`, `base_main_view.dart`, `base_main_wrapper.dart`, `shared/common/layout/` |
| C01 | `customer/views/restaurant/list/` |
| C02–C04 | `customer/views/restaurant/detail/`, `menu/`, `product_detail_view.dart` |
| C05–C07 | `customer/views/cart/` |
| C08–C09 | `customer/views/payment/` |
| C10–C12 | `customer/views/orders/`, `customer/views/traking/` |
| C13 | `customer/views/wallet/customer_wallet_view.dart` |
| D01–D07 | `driver/views/home/` (cards in `card/`, confirmation in `delivery_confirmation_view.dart`), `driver/views/driver_success_ride_view.dart` |
| D08 | `driver/views/deliveries/` |
| M01–M05 | `manager/views/home/`, `manager/views/orders/` |
| M06–M08 | `manager/views/catalog/` |
| M09 | `manager/views/restaurant/opening_hours/` |
| M10 | `manager/views/manager_suspension_notice.dart`, `home/manager_suspension_banner.dart` |
| Theme today | `shared/common/config/app_theme.dart`, `shared/common/colors.dart` |
| Status colors today | `shared/enums/order_status.dart` |
