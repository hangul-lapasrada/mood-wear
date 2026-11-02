import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';

/// Profile page: login/register (written to the users table), logout and
/// My Orders loaded from the orders/order_items tables.
class ProfilePage extends StatefulWidget {
  final void Function(int) onLoggedIn;
  final VoidCallback onLogout;
  final int? userId;
  const ProfilePage(
      {super.key,
      required this.onLoggedIn,
      required this.onLogout,
      required this.userId});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final username = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  bool register = false, busy = false;

  @override
  void dispose() {
    for (final c in [username, email, phone, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (register && password.text != confirm.text) {
      show('Passwords do not match');
      return;
    }
    setState(() => busy = true);
    try {
      final r = await Api.post(
          register ? '/register' : '/login',
          register
              ? {
                  'username': username.text,
                  'email': email.text,
                  'phone': phone.text,
                  'password': password.text
                }
              : {'email': email.text, 'password': password.text});
      widget.onLoggedIn(r['id']);
      show(register ? 'Registration successful' : 'Logged in successfully');
    } catch (e) {
      show(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void show(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Widget field(String label, TextEditingController controller,
          {bool secret = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 19)),
            const SizedBox(height: 5),
            TextField(
                controller: controller,
                obscureText: secret,
                decoration: InputDecoration(
                    hintText: 'Enter $label',
                    filled: true,
                    fillColor: gray,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none),
                    isDense: true))
          ]));

  @override
  Widget build(BuildContext context) => ListView(children: [
        const Padding(
            padding: EdgeInsets.all(18),
            child:
                Center(child: Text('Profile', style: TextStyle(fontSize: 18)))),
        const SizedBox(height: 35),
        const Icon(Icons.account_circle_outlined, size: 90),
        if (widget.userId != null) ...[
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                  onPressed: widget.onLogout,
                  child: const Text('Logout'))),
          // Orders live in the orders/order_items tables.
          FutureBuilder<List<Map<String, dynamic>>>(
              future: Api.orders(widget.userId!),
              builder: (context, s) {
                if (!s.hasData) {
                  return const Padding(
                      padding: EdgeInsets.all(22),
                      child: Center(child: CircularProgressIndicator()));
                }
                final orders = s.data!;
                return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Orders',
                              style: TextStyle(fontSize: 21)),
                          const SizedBox(height: 12),
                          if (orders.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                    'No orders yet — your purchases will appear here.')),
                          for (final o in orders)
                            Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                color: gray,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Order #${o['id']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${o['created_at']}'),
                                      for (final it in (o['items'] as List<dynamic>)
                                          .map((e) =>
                                              Map<String, dynamic>.from(e)))
                                        Text(
                                            '${it['name']} x${it['quantity']} (${it['size']})',
                                            softWrap: true),
                                      Text('Address: ${o['address']}'),
                                      Text('Total: THB ${o['total']}')
                                    ]))
                        ]));
              })
        ],
        Padding(
            padding: const EdgeInsets.fromLTRB(47, 45, 47, 20),
            child: Column(children: [
              if (register) field('Username', username),
              field('Email', email),
              if (register) field('Phone Number', phone),
              field('Password', password, secret: true),
              if (register) field('Confirm Password', confirm, secret: true),
              SizedBox(
                  width: 160,
                  child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF444444)),
                      onPressed: busy ? null : submit,
                      child: Text(register ? 'Register' : 'Login'))),
              TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(
                      register ? 'Already Have Account?' : 'New? Register',
                      style: const TextStyle(color: Colors.grey)))
            ]))
      ]);
}
