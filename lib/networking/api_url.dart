//
const String mainUrl = "https://ums.visionbroadband.in";   // STAGE URL

const String baseUrl = mainUrl + "/api/v1/subscriber";


// auth
const String LOGIN_URL = baseUrl + "/login";
const String REGISTER_DEVICE = baseUrl + "/register-device";
const String GET_PERMISSIONS = baseUrl + "/permissions";
const String CHANGE_PASSWORD = baseUrl + "/change-password";
const String CHANGE_MAC_ADDRESS = baseUrl + "/change-mac-address";
const String LOGOUT_URL = baseUrl + "/logout";

//Dashboard
const String DASHBOARD = baseUrl + "/details";
const String RECENT_ACTIVITY = baseUrl + "/activity-logs";
const String REFERRAL_DASHBOARD = baseUrl + "/referral-dashboard";
const String CLAIM_REQUEST = baseUrl + "/request-claim";
const String NOTIFICATION = baseUrl + "/notifications";
const String CONTACT_US_URL = baseUrl + "/contact-us";
const String GET_LEDGERS_DATA = baseUrl + "/ledgers";
const String GET_SERVICE_HISTORY = baseUrl + "/service-history";
const String GET_ONLINE_TRANSACTION = baseUrl + "/online-transactions";
const String GET_UNPAID_AMOUNT = baseUrl + "/unpaid-amount";
const String GET_INVOICES_DATA = baseUrl + "/invoices";
const String GET_INVOICES_DETAILS = baseUrl + "/invoice-details";
const String DOWNLOAD_INVOICES = baseUrl + "/download-invoice";

//RECHARGE/POPUP
const String GET_RECHARGE_PACKAGE = baseUrl + "/packages";
const String GET_PAYMENT_GATEWAY = baseUrl + "/payment-gateways";
const String GET_PAYMENT_SUMMARY = baseUrl + "/payment-summary";
const String GET_ADVANCE_RECHARGE = baseUrl + "/advance-recharges";
const String ACTIVE_ADVANCE_RECHARGE = baseUrl + "/activate-advance-recharge";

// PIN RECHARGE
const String GET_PIN_DETAILS = baseUrl + "/pin-details";
const String RECHARGE_BY_PIN = baseUrl + "/recharge-pin";

//PAYMENT GATEWAY
const String ADD_RECHARGE_REQUEST = baseUrl + "/recharge";
const String ADD_PAYMENT = baseUrl + "/add-payment";
const String GET_PAYMENT_STATUS = baseUrl + "/payment-order-status";

//STATISTICS
const String GET_ONLINE_SESSIONS = baseUrl + "/online-sessions";
const String GET_USAGE_SESSIONS = baseUrl + "/usage-sessions";
const String USAGE_SESSIONS_REPORT = baseUrl + "/usage-session-report";
const String MRGT_GRAPH_DATA = baseUrl + "/mrtg-graph-data";
const String LIVE_TRAFFIC_DATA = baseUrl + "/live-traffic-data";

//TICKET
const String GET_SUPPORT_TICKET = baseUrl + "/tickets";
const String CREATE_TICKET_URL = baseUrl + "/ticket/create";
const String GET_TICKET_DETAILS = baseUrl + "/ticket/details";
const String ADD_COMMENT_URL = baseUrl + "/ticket/add-comment";
const String TICKET_RESOLVE_URL = baseUrl + "/ticket/resolve";
const String TICKET_CLOSE_URL = baseUrl + "/ticket/close";
const String TICKET_REOPEN_URL = baseUrl + "/ticket/reopen";

//WIFI SETTING
const String WAN_SETTING_URL = baseUrl + "/acs_device_wan_setting";
const String WIFI_SETTING_URL = baseUrl + "/acs_device_wifi_setting";
const String WLAN_SETTING_URL = baseUrl + "/acs_device_wlan_host";
const String REFRESH_WIFI_DATA = baseUrl + "/refresh_wifi_data";
const String REFRESH_WAN_DATA = baseUrl + "/refresh_wan_data";
const String REFRESH_WLAN_DATA = baseUrl + "/refresh_wlan_host_data";
const String UPDATE_WIFI_DATA = baseUrl + "/update_wifi_data";
const String REBOOT_DEVICE_URL = baseUrl + "/reboot_device";
const String REFRESH_DEVICE_DATA = baseUrl + "/refresh_all_device_data";

// common
const String GET_PROFILE_DETAILS = baseUrl + "/details";
const String GET_SITE_SETTINGS = baseUrl + "/site-settings";
const String UPDATE_PROFILE_DETAILS = baseUrl + "/update-profile";
