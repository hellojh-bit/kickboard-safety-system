
import 'package:flutter/material.dart';
import 'auth_api.dart';

class FindIdView extends StatefulWidget {
  const FindIdView({super.key});

  @override
  State<FindIdView> createState() => _FindIdViewState();
}

class _FindIdViewState extends State<FindIdView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _foundId;
  bool _isLoading = false;

  Future<void> _findId() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이름과 전화번호를 입력해주세요")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthApi.findId(
        name: _nameController.text,
        phone: _phoneController.text,
      );

      if (!mounted) return;

      if (result['result'] == 'SUCCESS') {
        setState(() {
          _foundId = result['user_id'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "아이디 찾기 실패")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("서버 연결 실패")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFb5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "아이디 찾기",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "이름",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "전화번호",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _findId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D191),
                  ),
                  child: Text(
                    _isLoading ? "조회 중..." : "아이디 찾기",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (_foundId != null) ...[
                const SizedBox(height: 25),
                Text(
                  "찾은 아이디: $_foundId",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "로그인으로 돌아가기",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
