public enum ADIFField: String, CaseIterable, Sendable {
  case call = "CALL"
  case mode = "MODE"
  case submode = "SUBMODE"
  case freq = "FREQ"
  case freqRx = "FREQ_RX"
  case band = "BAND"
  case qsoDate = "QSO_DATE"
  case timeOn = "TIME_ON"
  case qsoDateOff = "QSO_DATE_OFF"
  case timeOff = "TIME_OFF"
  case rstSent = "RST_SENT"
  case rstRcvd = "RST_RCVD"
  case txPwr = "TX_PWR"
  case stationCallsign = "STATION_CALLSIGN"
  // swift-format-ignore
  case operator_ = "OPERATOR"
  case myCall = "MY_CALL"
  case myGridsquare = "MY_GRIDSQUARE"
  case gridsquare = "GRIDSQUARE"
  case name = "NAME"
  case qth = "QTH"
  case state = "STATE"
  case country = "COUNTRY"
  case cqz = "CQZ"
  case ituz = "ITUZ"
  case cont = "CONT"
  case iota = "IOTA"
  case dxcc = "DXCC"
  case comment = "COMMENT"
  case notes = "NOTES"
  case qslmsg = "QSLMSG"
  case stx = "STX"
  case srx = "SRX"
  case stxString = "STX_STRING"
  case srxString = "SRX_STRING"
  case contestId = "CONTEST_ID"
  case propMode = "PROP_MODE"
  case satName = "SAT_NAME"
  case satMode = "SAT_MODE"
  case sotaRef = "SOTA_REF"
  case wwffRef = "WWFF_REF"
  case potaRef = "POTA_REF"
  case darcDok = "DARC_DOK"
  case email = "EMAIL"
  case cnty = "CNTY"
  case region = "REGION"
  case lat = "LAT"
  case lon = "LON"
  case antAz = "ANT_AZ"
  case antEl = "ANT_EL"
  case antPath = "ANT_PATH"
  case aIndex = "A_INDEX"
  case kIndex = "K_INDEX"
  case sfi = "SFI"
  case rxPwr = "RX_PWR"
  case prefix = "PREFIX"
}

extension QSO {
  public subscript(field: ADIFField) -> String {
    get {
      switch field {
      case .call: return call
      case .mode: return mode
      case .submode: return submode
      case .freq: return frequency
      case .freqRx: return frequencyRx
      case .band: return band
      case .qsoDate: return qsoDate
      case .timeOn: return timeOn
      case .qsoDateOff: return qsoDateOff
      case .timeOff: return timeOff
      case .rstSent: return rstSent
      case .rstRcvd: return rstReceived
      case .txPwr: return txPower
      case .stationCallsign: return stationCallsign
      case .operator_: return operatorCall
      case .myCall: return myCall
      case .myGridsquare: return myGridsquare
      case .gridsquare: return gridsquare
      case .name: return name
      case .qth: return qth
      case .state: return state
      case .country: return country
      case .cqz: return cqZone
      case .ituz: return ituZone
      case .cont: return continent
      case .iota: return iota
      case .dxcc: return dxcc
      case .comment: return comment
      case .notes: return notes
      case .qslmsg: return qslMessage
      case .stx: return stx
      case .srx: return srx
      case .stxString: return stxString
      case .srxString: return srxString
      case .contestId: return contestId
      case .propMode: return propMode
      case .satName: return satName
      case .satMode: return satMode
      case .sotaRef: return sotaRef
      case .wwffRef: return wwffRef
      case .potaRef: return potaRef
      case .darcDok: return darcDok
      case .email: return email
      case .cnty: return county
      case .region: return region
      case .lat: return latitude
      case .lon: return longitude
      case .antAz: return antAzimuth
      case .antEl: return antElevation
      case .antPath: return antPath
      case .aIndex: return aIndex
      case .kIndex: return kIndex
      case .sfi: return sfi
      case .rxPwr: return rxPower
      case .prefix: return prefix
      }
    }
    set {
      switch field {
      case .call: call = newValue
      case .mode: mode = newValue
      case .submode: submode = newValue
      case .freq: frequency = newValue
      case .freqRx: frequencyRx = newValue
      case .band: band = newValue
      case .qsoDate: qsoDate = newValue
      case .timeOn: timeOn = newValue
      case .qsoDateOff: qsoDateOff = newValue
      case .timeOff: timeOff = newValue
      case .rstSent: rstSent = newValue
      case .rstRcvd: rstReceived = newValue
      case .txPwr: txPower = newValue
      case .stationCallsign: stationCallsign = newValue
      case .operator_: operatorCall = newValue
      case .myCall: myCall = newValue
      case .myGridsquare: myGridsquare = newValue
      case .gridsquare: gridsquare = newValue
      case .name: name = newValue
      case .qth: qth = newValue
      case .state: state = newValue
      case .country: country = newValue
      case .cqz: cqZone = newValue
      case .ituz: ituZone = newValue
      case .cont: continent = newValue
      case .iota: iota = newValue
      case .dxcc: dxcc = newValue
      case .comment: comment = newValue
      case .notes: notes = newValue
      case .qslmsg: qslMessage = newValue
      case .stx: stx = newValue
      case .srx: srx = newValue
      case .stxString: stxString = newValue
      case .srxString: srxString = newValue
      case .contestId: contestId = newValue
      case .propMode: propMode = newValue
      case .satName: satName = newValue
      case .satMode: satMode = newValue
      case .sotaRef: sotaRef = newValue
      case .wwffRef: wwffRef = newValue
      case .potaRef: potaRef = newValue
      case .darcDok: darcDok = newValue
      case .email: email = newValue
      case .cnty: county = newValue
      case .region: region = newValue
      case .lat: latitude = newValue
      case .lon: longitude = newValue
      case .antAz: antAzimuth = newValue
      case .antEl: antElevation = newValue
      case .antPath: antPath = newValue
      case .aIndex: aIndex = newValue
      case .kIndex: kIndex = newValue
      case .sfi: sfi = newValue
      case .rxPwr: rxPower = newValue
      case .prefix: prefix = newValue
      }
    }
  }
}
