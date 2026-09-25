import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:guardiao/core/errors/failures.dart';
import 'package:guardiao/core/usecases/usecase.dart';
import 'package:guardiao/features/family/domain/entities/family_link_entity.dart';
import 'package:guardiao/features/family/domain/repositories/family_repository.dart';
import 'package:guardiao/features/family/domain/usecases/get_family_links_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/request_family_link_usecase.dart';
import 'package:guardiao/features/family/domain/usecases/respond_family_link_usecase.dart';
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

    test('RequestFamilyLinkUseCase normaliza o código digitado', () async {
      when(
        () => mockRepository.requestLinkByCode(any()),
      ).thenAnswer((_) async => const Right('Maria'));

      final result = await RequestFamilyLinkUseCase(mockRepository)(
        ' k7p-2qx ',
      );

      expect(result, const Right('Maria'));
      verify(() => mockRepository.requestLinkByCode('K7P2QX')).called(1);
    });

    test('RequestFamilyLinkUseCase rejeita código incompleto', () async {
      final result = await RequestFamilyLinkUseCase(mockRepository)('K7P');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => mockRepository.requestLinkByCode(any()));
    });

    test('RespondFamilyLinkUseCase autoriza o vínculo', () async {
      when(
        () => mockRepository.respondToLink(
          linkId: any(named: 'linkId'),
          accept: any(named: 'accept'),
        ),
      ).thenAnswer((_) async => const Right(null));

      final result = await RespondFamilyLinkUseCase(mockRepository)(
        const RespondFamilyLinkParams(linkId: 'link-1', accept: true),
      );

      expect(result, const Right(null));
      verify(
        () => mockRepository.respondToLink(linkId: 'link-1', accept: true),
      ).called(1);
    });
  });
}
