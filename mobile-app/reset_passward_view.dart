import 'package:flutter/material.dart';
import 'auth_api.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});
  
  // reset_password_view.dart 수정, 사유 : register_view.dart의 ResigerView()함수가 겹침
  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  // 비밀번호 재설정에 필요한 4개의 컨트롤러
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPwController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty || 
        _phoneController.text.isEmpty || _newPwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 항목을 입력해주세요")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthApi.resetPassword(
        userId: _idController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        newPassword: _newPwController.text,
      );

      if (!mounted) return;

      if (result['result'] == 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
        );
        Navigator.pop(context); // 로그인 화면으로 돌아가기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "변경 실패")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("서버 통신 오류가 발생했습니다.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("비밀번호 재설정")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _idController, decoration: const InputDecoration(hintText: "아이디")),
              const SizedBox(height: 10),
              TextField(controller: _nameController, decoration: const InputDecoration(hintText: "이름")),
              const SizedBox(height: 10),
              TextField(controller: _phoneController, decoration: const InputDecoration(hintText: "전화번호")),
              const SizedBox(height: 10),
              TextField(controller: _newPwController, decoration: const InputDecoration(hintText: "새 비밀번호"), obscureText: true),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D191)),
                  child: Text(_isLoading ? "처리 중..." : "비밀번호 변경", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
