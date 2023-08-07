class Model{
  List<dynamic> name, address, phoneNumber, email, designation, companyName, website;

  Model({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.designation,
    required this.companyName,
    required this.website,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['address'] = address;
    data['phone_number'] = phoneNumber;
    data['email'] = email;
    data['designation'] = designation;
    data['company_name'] = companyName;
    data['website'] = website;
    return data;
  }
}