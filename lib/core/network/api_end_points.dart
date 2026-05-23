class ApiEndPoints {
  static String baseUrl = "http://172.17.1.65:3000/api/v1";
  static String imgBaseUlr = "http://172.17.1.65:3000";
  // auth..

  static const login = "/auth/sign-in";

  // business partner
  static const addBusinessPartner = "/bp";
  static const uploadFilesOfBusinessPartner = "/bp/upload";
  static const businessTypeAndCategory = "/bp/categories-and-types";
  static const allowedAttachment = "/bp/allowed-attachments";
}
