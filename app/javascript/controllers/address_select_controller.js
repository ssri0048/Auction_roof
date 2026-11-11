import { Controller } from "@hotwired/stimulus"

// Province → district → sub-district selects. Loads the next list from the server
// when a choice changes and fills the postcode from the chosen sub-district.
export default class extends Controller {
  static targets = [ "province", "district", "subDistrict", "postcode" ]
  static values = { districtsUrl: String, subDistrictsUrl: String }

  async loadDistricts() {
    this.reset(this.districtTarget, "เลือกอำเภอ")
    this.reset(this.subDistrictTarget, "เลือกตำบล")
    this.postcodeTarget.value = ""
    if (!this.provinceTarget.value) return

    const rows = await this.fetchJson(this.districtsUrlValue, { province_id: this.provinceTarget.value })
    rows.forEach((row) => this.districtTarget.add(new Option(row.name, row.id)))
  }

  async loadSubDistricts() {
    this.reset(this.subDistrictTarget, "เลือกตำบล")
    this.postcodeTarget.value = ""
    if (!this.districtTarget.value) return

    const rows = await this.fetchJson(this.subDistrictsUrlValue, { district_id: this.districtTarget.value })
    rows.forEach((row) => {
      const option = new Option(row.name, row.id)
      option.dataset.postcode = row.postcode
      this.subDistrictTarget.add(option)
    })
  }

  fillPostcode() {
    const option = this.subDistrictTarget.selectedOptions[0]
    this.postcodeTarget.value = option?.dataset.postcode || ""
  }

  reset(select, placeholder) {
    select.replaceChildren(new Option(placeholder, ""))
  }

  async fetchJson(url, params) {
    const response = await fetch(`${url}?${new URLSearchParams(params)}`, { headers: { Accept: "application/json" } })
    return response.ok ? response.json() : []
  }
}
