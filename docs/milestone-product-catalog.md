# Milestone: Product Catalog (Admin) — จัดการรายการสินค้า

Status: **Draft for review** · Last updated: 2026-11-11

## 1. Goal

Admins can **create, view, edit and archive product items**, the assets that will
later be put up for auction. Each item can have **multiple photos** (หลายรูปภาพ).
The same features are available through a JSON API under `api/v1`.

**Out of scope for this milestone:** creating auctions and lots, bidding, and the
public product pages. This milestone only produces the items that those later
milestones will use.

## 2. What the paper sketch shows

| Sketch element | Interpretation | Enhancement |
|---|---|---|
| Title **"Product Cat (Admin)"** | Admin-only product catalog page | Breadcrumb `ผู้ดูแลระบบ › รายการสินค้า` plus the total count, e.g. "128 รายการ" |
| **Filter ▾** (top left) | Filter dropdown | Filter by category, status and location, shown as removable chips |
| **Create +** | Opens the create form | Primary brand-color button `+ เพิ่มสินค้า` |
| **Search** box | Keyword search | Searches name, asset code and description, with a 300 ms debounce and the query kept in the URL |
| Grid of cards (image + 2–3 text lines) | Product cards: photo, name, details | Card shows the cover photo, photo count badge (📷 5), name, category, status badge and asset code |
| **Edit** circle on each card | Edit shortcut | Hover or tap shows `แก้ไข`. Clicking the card opens a detail view |
| **◁ 1 / 15 ▷** | Pagination | Kept as drawn, plus a "per page" select (12 / 24 / 48) |
| Green sticky note | Create/Edit **modal** | Modal on desktop, full-screen sheet on mobile |
| ↑ upload box + **○ ○ ○** dots | Multi-photo upload with a **photo slider** (สไลด์ดูรูป) | Drag & drop, thumbnails strip, reorder, set cover, delete. ◀ ▶ arrows, swipe on mobile, and a `1 / 5` counter |
| **ชื่อ** | Name | required |
| **type** | Category (ประเภท) | Select from managed categories |
| **Des** | Description | Multi-line text |
| **? owner** | **Item owner (เจ้าของสินค้า):** the person who brought the item to the admin to list | Owner name* and phone*, optionally linked to a registered user via autocomplete, plus a note. Admin-only, never shown to bidders |
| **○1 ○2** + small box | **Photo slider indicators:** swipe through the uploaded photos | Each dot is one photo, the current photo is filled. The small box is the thumbnail strip |
| Two buttons bottom right | `ยกเลิก` (Cancel) / `บันทึก` (Save) | Save is disabled while photos are still uploading. A confirm dialog appears if the user closes with unsaved changes |

### Enhanced wireframe

```text
┌───────────────────────────────────────────────────────────────────────────┐
│ ผู้ดูแลระบบ › รายการสินค้า (128)                                             │
│ [ตัวกรอง ▾] [ประเภท: หม้อแปลง ✕] [สถานะ: ร่าง ✕]  [🔍 ค้นหา........] [+ เพิ่มสินค้า] │
├───────────────────────────────────────────────────────────────────────────┤
│ ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐                              │
│ │ 📷 5   │  │ 📷 2   │  │  (no   │  │ 📷 8   │                              │
│ │  cover │  │  cover │  │ photo) │  │  cover │                              │
│ │   [✎] │  │   [✎] │  │   [✎] │  │   [✎] │                              │
│ └────────┘  └────────┘  └────────┘  └────────┘                              │
│ หม้อแปลง 50kVA  รถกระบะ ...  สายไฟ ...   ...                                │
│ PEA-TR-00123   PEA-VH-0042   ...                                          │
│ [พร้อมประมูล]   [ร่าง]                                                       │
│                                                                           │
│                ◁  1 / 15  ▷        แสดง [12 ▾] ต่อหน้า                      │
└───────────────────────────────────────────────────────────────────────────┘

Create / Edit modal
┌──────────────────────────────── เพิ่มสินค้า ──────────────────── ✕ ┐
│ ┌───────────────────────────────────────────────┐                 │
│ │        ↑  ลากไฟล์มาวาง หรือ คลิกเพื่อเลือกรูป        │                 │
│ │        JPG / PNG / WEBP · สูงสุด 10 รูป · 10MB/รูป │                 │
│ └───────────────────────────────────────────────┘                 │
│        ◀   [ current photo preview ]   ▶        1 / 4             │
│                  ●  ○  ○  ○      ← slide dots (สไลด์ดูรูป)            │
│ [★cover][img2][img3][img4 ⏳60%][ + ]   ← drag to reorder, ✕ to remove │
│                                                                   │
│ ชื่อสินค้า*  [______________________]  ประเภท* [หม้อแปลงไฟฟ้า ▾]       │
│ รหัสทรัพย์สิน [PEA-TR-00123]                                          │
│ เจ้าของสินค้า* [ค้นหาผู้ใช้ หรือพิมพ์ชื่อ...]   เบอร์โทร* [08x-xxx-xxxx]      │
│ จำนวน* [ 1 ] หน่วย [เครื่อง ▾]          สภาพ  ○ ใช้งานได้ ○ ชำรุด ○ ซาก     │
│ สถานที่ตั้ง [จังหวัด ▾]                 ราคาประเมิน (บาท) [________]        │
│ รายละเอียด                                                          │
│ [_____________________________________________________________]  │
│ สถานะ  ● ร่าง  ○ พร้อมประมูล                                           │
│                                              [ยกเลิก]  [บันทึก]       │
└───────────────────────────────────────────────────────────────────┘
```

## 3. Data model

```text
product_categories
  id, name (unique), description, position (int), active (bool, default true), timestamps

products
  id
  product_category_id   FK, required
  name                  string, required, ≤ 200
  asset_code            string, optional, unique when present    # รหัสทรัพย์สิน
  description           text
  owner_name            string, required                         # เจ้าของสินค้า: the person who brought the item in
  owner_phone           string, required, 10 digits starting with 0 (same rule as users.phone)
  owner_user_id         FK users, optional                       # set if the owner is a registered user
  owner_note            text, optional                           # e.g. agreement or commission notes
                        # owner_* is personal data: admin-only, excluded from any public API
  quantity              integer, default 1, > 0
  unit                  string, default "ชิ้น"
  condition             enum: usable | damaged | scrap           # ใช้งานได้ / ชำรุด / ซาก
  location_province     string
  appraised_price       decimal(14,2), optional                  # ราคาประเมิน
  status                enum: draft | ready | archived           # ร่าง / พร้อมประมูล / เก็บถาวร
  created_by_id, updated_by_id   FK users
  timestamps
  indexes: status, product_category_id, asset_code (unique, partial), name (pg_trgm for search)

product_photos
  id, product_id FK, position (int), has_one_attached :image, timestamps
  index: [product_id, position]
```

**Why a `product_photos` table** instead of `has_many_attached :photos`: plain
attachments have no stable order and can't mark a cover photo. A separate model
with a `position` column gives us both. The cover photo is simply `position = 0`.

**Photo rules**

- Allowed types: `image/jpeg`, `image/png`, `image/webp`. HEIC from iPhones is
  converted on upload, or rejected with a clear message.
- Max **10 MB** per photo and **10 photos** per product, enforced in the model and
  the UI.
- Variants (via `image_processing`, already in the Gemfile):
  - `thumb`: 400×400, cropped
  - `medium`: 1200 px wide
  - `large`: 2000 px wide, for zooming
- Photos may contain metadata. Strip EXIF/GPS when generating variants.

**Permissions:** add `"manage_products" => "จัดการรายการสินค้า"` to
`Role::PERMISSIONS`. Every admin page and API endpoint in this milestone requires
it.

## 4. Milestone tasks

Each row below becomes one issue or PR. Estimates are in ideal days.

| # | Task | Acceptance criteria | Est. |
|---|---|---|---|
| **0** | **Prerequisites** | `manage_products` permission exists and an admin role is seeded with it. **Production photo storage moved off local disk** (see §7, risk 1) | 1 |
| **1** | **Models & migrations** | `ProductCategory`, `Product`, `ProductPhoto` with validations and enums. Seeds create categories such as หม้อแปลงไฟฟ้า, ยานพาหนะ, สายไฟ/เศษโลหะ, อุปกรณ์ไฟฟ้า, เครื่องจักร, ครุภัณฑ์สำนักงาน. Model tests pass | 1 |
| **2** | **Admin list page** (`/admin/products`) | Card grid as in the sketch, responsive (4 / 3 / 2 / 1 columns). Cover photo, or a placeholder when there is none. Name, category, asset code, status badge and photo count on each card. Empty state with a create button. Users without permission get 403 or a redirect | 2 |
| **3** | **Search, filter, pagination** | Search matches name, asset code and description, case-insensitive with Thai support. Filters for category, status, condition and province appear as chips. Pagination shows `◁ 1 / 15 ▷` with 12 / 24 / 48 per page. Search, filter and page state live in the URL, so they survive a reload and the Back button. Archived items are hidden unless filtered for | 2 |
| **4** | **Create / Edit modal** | Turbo Frame modal that opens from `+ เพิ่มสินค้า` and from the card's ✎ button. Server-side validation errors appear in Thai beside each field. Saving updates the card in the grid without a full reload (Turbo Stream). Closing with unsaved changes asks for confirmation. **Owner field:** autocomplete that searches registered users by name or phone, with fallback to typing the name and phone by hand | 2 |
| **5** | **Multi-photo upload** | Drag & drop or file picker, several files at once. Active Storage **direct upload**, with a progress bar per file. Thumbnail strip where the user can drag to reorder, mark a cover (★) and delete (✕). Limits for count, size and type are checked in the browser and again on the server. Save is disabled while uploads are running. **Photo slider** in the window (◀ ▶, swipe, dots, `1 / n`) | 3 |
| **6** | **Product detail / preview** | Clicking a card opens the photo slider (the ○○○ dots from the sketch), owner name and phone, all fields, created/updated by and when, and Edit / Archive buttons | 1 |
| **7** | **Archive & delete** | Archive is a soft delete (`status = archived`) and can be restored. Hard delete is allowed only for drafts that have never been used in an auction. Every destructive action asks for confirmation | 1 |
| **8** | **Category management** (`/admin/product_categories`) | Simple list with create, rename, reorder and deactivate. A category that still has products cannot be deleted, only deactivated | 1 |
| **9** | **JSON API** (§5) | Endpoints match the spec, request tests cover 200 / 201 / 401 / 403 / 404 / 422, and examples are documented. Optional: export a Postman collection | 2 |
| **10** | **Audit & QA** | `created_by` and `updated_by` are filled in. System tests cover create with 3 photos → reorder → edit → archive. Manual check on mobile Safari and Chrome | 1 |
| | | **Total** | **~17 days** |

**Definition of done (whole milestone):** all tasks merged, `bin/rails test`
green, deployed to Railway, and photos still present after a redeploy.

## 5. API design

The API follows the existing conventions in `Api::V1::BaseController`:

- authentication uses the session cookie
- errors look like `{ "error": "..." }` or `{ "errors": { field: [msg] } }`
- status codes: 401 (not logged in), 403 (missing `manage_products`), 404, 422 (validation)

Routes sit under an `admin` namespace, so a public, read-only `GET /api/v1/products`
can be added later for bidders without mixing the two.

### Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/v1/admin/products` | List, with search, filters and pagination |
| GET | `/api/v1/admin/products/:id` | Get one product, including photos |
| POST | `/api/v1/admin/products` | Create |
| PATCH | `/api/v1/admin/products/:id` | Update fields and/or photo order |
| POST | `/api/v1/admin/products/:id/archive` | Archive |
| POST | `/api/v1/admin/products/:id/restore` | Restore from archive |
| DELETE | `/api/v1/admin/products/:id` | Hard delete (drafts only, otherwise 422) |
| POST | `/api/v1/admin/products/:id/photos` | Attach photos (`signed_ids` or multipart) |
| PATCH | `/api/v1/admin/products/:id/photos/order` | Reorder: `{ "photo_ids": [9, 7, 8] }`. The first one becomes the cover |
| DELETE | `/api/v1/admin/products/:id/photos/:photo_id` | Remove one photo |
| POST | `/rails/active_storage/direct_uploads` | Built into Rails: returns a `signed_id` and upload URL for direct upload |
| GET/POST/PATCH/DELETE | `/api/v1/admin/product_categories[/:id]` | Category CRUD |

### List: `GET /api/v1/admin/products`

Query parameters:

| Param | Example | Notes |
|---|---|---|
| `q` | `หม้อแปลง` | Searches name, asset_code and description |
| `category_id` | `3` | |
| `status` | `draft,ready` | Comma-separated. The default excludes `archived` |
| `condition` | `usable` | |
| `province` | `เชียงใหม่` | |
| `sort` | `-updated_at` | `name`, `created_at`, `updated_at`. A leading `-` means descending |
| `page`, `per_page` | `1`, `12` | `per_page` max is 48 |

```json
{
  "data": [
    {
      "id": 123,
      "name": "หม้อแปลงไฟฟ้า 50 kVA",
      "asset_code": "PEA-TR-00123",
      "category": { "id": 3, "name": "หม้อแปลงไฟฟ้า" },
      "status": "ready",
      "condition": "damaged",
      "quantity": 1,
      "unit": "เครื่อง",
      "cover_photo": { "id": 9, "thumb_url": "https://…/thumb.webp" },
      "photos_count": 5,
      "updated_at": "2026-11-11T09:30:00+07:00"
    }
  ],
  "meta": { "page": 1, "per_page": 12, "total_pages": 15, "total_count": 172 }
}
```

### Create: `POST /api/v1/admin/products`

Recommended flow:

1. Upload each file directly to storage with Active Storage direct upload. Each
   upload returns a `signed_id`.
2. Create the product, sending the `signed_id`s. Their order becomes the photo
   order.

```json
{
  "product": {
    "name": "หม้อแปลงไฟฟ้า 50 kVA",
    "product_category_id": 3,
    "asset_code": "PEA-TR-00123",
    "description": "ถอดจากสถานีย่อย…",
    "owner_name": "สมศักดิ์ รักดี",
    "owner_phone": "0812345678",
    "owner_user_id": null,
    "owner_note": "ส่งมอบของวันที่ 10 พ.ย.",
    "quantity": 1,
    "unit": "เครื่อง",
    "condition": "damaged",
    "location_province": "เชียงใหม่",
    "appraised_price": "25000.00",
    "status": "draft",
    "photo_signed_ids": ["eyJfcmFpbHMi…", "eyJfcmFpbHMi…"]
  }
}
```

A plain `multipart/form-data` request with `product[photos][]` files is also
accepted, for simple clients and tests.

**201** returns the full product, the same shape as `GET /:id`:

```json
{
  "id": 123,
  "name": "หม้อแปลงไฟฟ้า 50 kVA",
  "...": "...",
  "photos": [
    { "id": 9, "position": 0, "thumb_url": "…", "medium_url": "…", "large_url": "…",
      "filename": "front.jpg", "byte_size": 845123 }
  ],
  "created_by": { "id": 1, "name": "สมชาย ใจดี" },
  "created_at": "…", "updated_at": "…"
}
```

**422** returns field errors:

```json
{ "errors": { "name": ["ต้องกรอก"], "photos": ["อัปโหลดได้สูงสุด 10 รูป"] } }
```

### Update: `PATCH /api/v1/admin/products/:id`

Send only the fields that change. `photo_ids` (optional) sets the full order and
also removes any photo not in the list. Use `photo_signed_ids` to add new photos
in the same request.

## 6. Implementation notes

- **Controllers:**
  - `Admin::ProductsController` and `Admin::ProductCategoriesController` (HTML + Turbo)
  - `Api::V1::Admin::ProductsController` and `Api::V1::Admin::ProductPhotosController`
  - a shared `require_permission(:manage_products)` `before_action`
- **Search:** start with `ILIKE` on name and asset_code. Add the `pg_trgm` index
  if the list gets slow.
- **Pagination:** add the `pagy` gem. It's lightweight and works with both HTML
  and JSON.
- **Frontend:** Stimulus controllers `photo-uploader` (direct upload, progress,
  drag-to-reorder using SortableJS via importmap) and `modal`. Use PEA brand
  colors and the Prompt font that are already in the app.
- **N+1:** `Product.includes(:product_category, cover_photo: { image_attachment: :blob })`
  on the list page.
- **Accessibility:** alt text defaults to the product name plus `รูปที่ n`, buttons
  can be used by keyboard, and the modal traps focus.

## 7. Risks

1. **Photos will disappear in production.** `config/environments/production.rb`
   uses `active_storage.service = :local`, and Railway's container disk is wiped
   on every deploy. Before this milestone ships, move photo storage to S3,
   Cloudflare R2 or another S3-compatible store, or mount a Railway Volume at
   `/rails/storage`. This also affects the documents users already upload at
   registration.
2. Large phone photos on slow mobile networks: use direct upload, and consider
   resizing in the browser to ≤ 2000 px before upload.
3. Products are referenced by future auction lots, so never hard-delete them once
   they have been used in an auction (task 7).

## 8. Open questions

Resolved:

- **owner** is the item owner, the person who brought the item to the admin.
- **○1 ○2** are the photo slider dots.
- Per-category custom fields are not needed.

Still open:

1. Is the appraised or starting price set on the product, or later on the auction lot?
2. Should the max photo count be 10, or higher?
3. Do we need bulk import from Excel, or a PEA asset system integration, in a
   later milestone?
4. Should the owner be able to see their own items' status once registered
   (via `owner_user_id`)? This would be a later milestone.
