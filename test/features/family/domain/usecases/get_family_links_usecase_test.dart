import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/family/domain/entities/family_link_entity.dart';
import 'package:guardiao/features/family/domain/repositories/family_repository.dart';
import 'package:guardiao/features/family/domain/usecases/accept_family_invite_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/get_family_links_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/send_family_invite_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockFamilyRepository extends Mock implements FamilyRepository {}

void main() {
  late MockFamilyRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockRepository = MockFamilyRepository();
  });

  const tLink = FamilyLinkEntity(
    id: 'link-1',
    monitoredUserId: 'u1',
    viewerUserId: 'u2',
    status: 'accepted',
  );

  group('Family UseCases', () {
    test('GetFamilyLinksUseCase retorna lista de vínculos', () async {
      final useCase = GetFamilyLinksUseCase(mockRepository);
      when(
        () => mockRepository.getFamilyLinks(),
      ).thenAnswer((_) async => const Right([tLink]));

      final result = await useCase(const NoParams());

      expect(result, const Right([tLink]));
      verify(() => mockRepository.getFamilyLinks()).called(1);
    });

    test('SendFamilyInviteUseCase cria convite com sucesso', () async {
      final useCase = SendFamilyInviteUseCase(mockRepository);
      when(
        () => mockRepository.createInvite(
          viewerUserId: any(named: 'viewerUserId'),
        ),
      ).thenAnswer((_) async => const Right(tLink));

      final result = await useCase(
        const SendFamilyInviteParams(viewerUserId: 'u2'),
      );

      expect(result, const Right(tLink));
      verify(() => mockRepository.createInvite(viewerUserId: 'u2')).called(1);
    });

    test('AcceptFamilyInviteUseCase aceita convite com sucesso', () async {
      final useCase = AcceptFamilyInviteUseCase(mockRepository);
      when(
        () => mockRepository.acceptInvite(linkId: any(named: 'linkId')),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase(
        const AcceptFamilyInviteParams(linkId: 'link-1'),
      );

      expect(result, const Right(null));
      verify(() => mockRepository.acceptInvite(linkId: 'link-1')).called(1);
    });
  });
}
