class ApiConstants {
  static String baseUrl = "http://mnctest.avena.pl";

  //Container Controller Endpoints
  static String getContainersList = "/api/containers/getList";

  //Orders Controller Endpoints
  static String createOrder = "/api/orders/createOrder";
  static String updateOrder = "/api/orders/updateOrder";
  static String getClientName(int id) => "/api/orders/getClientName/$id";
  static String setClientNumber = "/api/orders/setClientNumber";
  static String sendSms(int id) => "/api/orders/sendSms/$id";
  static String setClientName(int id) => "/api/orders/setClientName/$id";

  //Payment Controller Endpoints
  static String getPaymentMethods = "/api/payment/getPaymentMethods";
  static String paymentNotifySet(int id) => "/api/payment/notify/set/$id";
  static String paymentNotifyGet(int id) => "/api/payment/notify/get/$id";
  static String payBlik = "/api/payment/pay/blik";

  //Storage Controller Endpoints
  static String getProducts = "/api/storage/getProducts";
  static String getStorageState = "/api/storage/getStorageState";
  static String getProductStorageState(String orderName) => "/api/storage/getProductStorageState/$orderName";
  static String getProductImage(String fileName) => "/api/storage/getProductImage/$fileName";

  //Login Controller Endpoints
  static String smsLogin = "/api/smsLogin";
  static String getSmsToken = "/api/getSmsToken";
  static String loginToken = "/api/login_check";
}