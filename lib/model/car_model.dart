class CartModel {
  List<Map<String, dynamic>> items = [];

  void addItem(Map<String, dynamic> product) {
    items.add(product);
  }

  double get total {
    return items.fold(0.0, (sum, item) => sum + (item['precio'] * item['cart_quantity']));
  }
}
